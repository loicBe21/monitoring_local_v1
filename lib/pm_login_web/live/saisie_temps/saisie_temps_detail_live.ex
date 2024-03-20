defmodule PmLoginWeb.SaisieTemps.SaisieTempsDetailLive do

  #liveView qui charge la page de details d'une saisie
  #les parm ci dessous sont requis
  #  id de l'utilisateur correspondant au saise
  #  date du saisie
  # strat_date , end_date ,status , right =>pour maintenir la filtre en cas de retour ver la page espace admin
  # Controller => SaisieTempsController.details_1
  #Templates => template/saisie_temps/saisie_temps_details.html

  use Phoenix.LiveView
    alias PmLogin.Services
    alias PmLogin.Monitoring
    alias PmLogin.Utilities
    alias PmLogin.Login
    alias PmLogin.SaisieTemps
    alias PmLoginWeb.Router.Helpers, as: Routes

    def mount(_param, %{"curr_user_id" => curr_user_id , "user_id" => user_id , "date" => date , "start_date" => start_date , "end_date" => end_date , "status" => status , "right" => right , "username" => username}, socket) do

      date_saisie  = Utilities.parse_date_string(date)
      today = Date.utc_today()
      current_user =  Login.get_user!(curr_user_id)
      user_saisie = Login.get_user!(String.to_integer(user_id))
      projects = SaisieTemps.get_projects_avalable_for_saisie
      my_saisie = SaisieTemps.get_saisie_by_user_by_date(String.to_integer(user_id) , date_saisie)
      start_date = Utilities.parse_date_string(start_date)
      end_date = Utilities.parse_date_string(end_date)
      right = String.to_integer(right)
      status = String.to_integer(status)
      username =  username
      #verifie si la date est deja validé ou pas
      is_already_validee =
        case SaisieTemps.get_entrie_validee_line(date_saisie, user_saisie.id) do
          nil ->
            {false, nil}
          saisie when is_map(saisie) ->
            {true, saisie}
        end
      validation_line =
        case is_already_validee do
          {true , saisie_validation} ->
            saisie_validation
          _
           ->nil
        end
        IO.inspect validation_line
      #  layout =
      #   case current_user.right_id do
        #    1 -> {PmLoginWeb.LayoutView, "admin_layout_live.html"}
        #   2 -> {PmLoginWeb.LayoutView, "attributor_layout_live.html"}
          #  3 -> {PmLoginWeb.LayoutView, "contributor_layout_live.html"}
          # _ -> {}
          # end

      socket =
        socket
          |>assign(
            user_saisie: user_saisie ,
            current_user: current_user ,
            curr_user_id:  curr_user_id ,
            notifs: Services.list_my_notifications_with_limit(curr_user_id, 4),
            today: Utilities.simple_date_format1(today),
            date_today: today,
            date_saisie: Utilities.simple_date_format1(date_saisie),
            date_saisie_format_date: date_saisie ,
            projects: projects,
            my_saisie: my_saisie ,
            total_heure: SaisieTemps.sum_time_values(my_saisie),
            start_date: start_date ,
            end_date: end_date ,
            right: right ,
            status: status ,

            #pour la modification des saisie

            show_modal: false,
            entrie_to_edit: nil ,
            entrie_project: nil,
            entrie_task: nil,
            tasks: nil ,
            #variable pour marquer que la liste deroulante de projet n'es pas changer
            project_select_state: true,
            #true si la date est deja validee
            is_already_validee: is_already_validee ,
            validation_line: validation_line ,
            show_notif: false ,
            username: username
          )
      {:ok, socket , layout: {PmLoginWeb.LayoutView, "saisie_layout.html"}}
    end


  #evenement qui ouvre la pop-up d'edition de saisie (modification)
    def handle_event("edit_entrie",%{"entrie_id" => entrie_id}, socket) do
      to_edit = SaisieTemps.get_entrie_by_id(String.to_integer(entrie_id))
      to_edit_project = Monitoring.get_project!(to_edit.project_id)
      task_edit_entrie = Monitoring.get_task!(to_edit.task_id)
      tasks = SaisieTemps.get_tasks_by_project(to_edit.project_id)
      {:noreply , socket|>assign(show_modal: true , entrie_to_edit:  to_edit , entrie_project: to_edit_project ,entrie_task: task_edit_entrie , tasks: tasks)}
    end

  #evenement qui ferme la pop-up d'edition
    def handle_event("close_edit_modal",_params, socket) do
      {:noreply , socket|>assign(show_modal: false )}
    end


  #fonction qui ecoute les changement d'etat des input de la formulaire d'edition des saisie
  #event sur la liste deroulante de projet
  #par defaut la liste le projet du saisie a modifier est deja selectioner , et la taches aussi
  #event sur la liste deroulante de projet
    def handle_event("project_change",params, socket) do

      #si le projet a updater != projet dans la liste deroulante
      if socket.assigns.entrie_project.id != String.to_integer(params["project_id"]) do
          {:noreply , socket|>assign(
            tasks: SaisieTemps.get_tasks_by_project(String.to_integer(params["project_id"])),
            #status changer car la lise deroulant a ete modifier
            project_select_state: false
            )}
      else
            {:noreply , socket|>assign(
            tasks: SaisieTemps.get_tasks_by_project(String.to_integer(params["project_id"]))
            )}
      end

    end





  #fonction qui sauvgarde la modification d'une saisie
  #rechargde la nouvele liste de saisie avec la saisie modifier
  #recalcule la total d 'heure passé
    def handle_event("update_entrie",%{"user_id"=> user_id , "task_id" => task_id ,"project_id" => project_id ,"time_value" => time_value , "libele" => libele}  , socket) do
        SaisieTemps.update_entrie(socket.assigns.entrie_to_edit ,%{"user_id"=> user_id , "task_id" => task_id ,"project_id" => project_id ,"time_value" => time_value , "libele" => libele})
        my_saisie = SaisieTemps.get_saisie_by_user_by_date(socket.assigns.user_saisie.id , socket.assigns.date_saisie_format_date)
        {:noreply , socket |>assign(my_saisie:  my_saisie,total_heure: SaisieTemps.sum_time_values(my_saisie) , show_modal: false)}
    end



  #supprime une siaie
  #mis a jour la liste de saisie
  #re calcule la toatl d'heure passé
  #supprime directement la ligne dans la base de données
    def handle_event("delete_entrie", %{"entrie_id" => entrie_id}, socket) do
    # Convertir l'ID en entier si nécessaire
      entrie_id = String.to_integer(entrie_id)
      case SaisieTemps.delete_entrie(entrie_id) do
        {:ok , _} ->
          my_saisie = SaisieTemps.get_saisie_by_user_by_date(socket.assigns.user_saisie.id , socket.assigns.date_today)
          {:noreply , socket
          |> assign(
            my_saisie: my_saisie ,
            total_heure: SaisieTemps.sum_time_values(my_saisie)
          )}
        {:error , _} ->
          {:noreply , socket}
      end
    end




  #supprime une ligne de validation dans la base de donnees
  #utiliser pour annuler les validation
    def handle_event("delete_validation_line",%{"validation_line_id" => validation_id}, socket) do
      IO.inspect validation_id
      validation_id = String.to_integer(validation_id)
      url = Routes.saisie_temps_path(socket, :details1, socket.assigns.user_saisie.id,socket.assigns.date_saisie , start_date: Utilities.parse_date_to_html(socket.assigns.start_date) , end_date: Utilities.parse_date_to_html(socket.assigns.end_date), status: socket.assigns.status, right: socket.assigns.right  )
      case SaisieTemps.delete_validation_line(validation_id) do
         {:ok, _} ->
             {:noreply ,
                socket
                |>redirect(to: url)
             }
         _ ->
            {:noreply ,
              socket
              |>put_flash(:error , "erreur au cours de l'annulation du validation de la saisie")
            }

      end

    end



    def parse_integer_list(strings) do
      Enum.map(strings, &String.to_integer/1)
    end


    def render(assigns) do
      PmLoginWeb.SaisieTempsView.render("saisie_temps_detail.html" , assigns)
    end


end
