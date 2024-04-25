defmodule PmLoginWeb.SaisieTemps.SaisieIndexLive do

  #liveView qui charge la page index saisie de temps
  #Routes => get "/saisie_index" , SaisieTempsController , :index_saisie
  #Controller => SaisieTempsController.index_saisie
  #Templates => template/saisie_temps/saisie_page.html

  #{Routes.saisie_temps_path(@socket, :index_saisie , date: Utilities.parse_date_to_html(Date.utc_today()))}

  use Phoenix.LiveView
    alias PmLogin.Services
    alias PmLogin.Monitoring
    alias PmLogin.Utilities
    alias PmLogin.Login
    alias PmLogin.SaisieTemps
    alias PmLoginWeb.Router.Helpers, as: Routes

    def mount(_param, %{"curr_user_id" => curr_user_id , "date" => date}, socket) do

      #IO.inspect date
      today = Utilities.parse_date_string(date)
      #today = Date.utc_today()
      current_user =  Login.get_user!(curr_user_id)
      projects = SaisieTemps.get_projects_avalable_for_saisie
      #IO.inspect projects
      data_projects = Jason.encode!(projects)

      #IO.inspect data_projects
      my_saisie = SaisieTemps.get_saisie_by_user_by_date(curr_user_id , today)
      IO.inspect my_saisie
      #verifie si la date est deja validé ou pas
      is_already_validee =
        case  SaisieTemps.get_entrie_validee_line(today , curr_user_id) do
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
        #IO.inspect validation_line
      # IO.inspect my_saisie
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
            current_user: current_user ,
            curr_user_id:  curr_user_id ,
            notifs: Services.list_my_notifications_with_limit(curr_user_id, 4),
            today: Utilities.simple_date_format1(today),
            date_today: today,
            projects: projects,
            my_saisie: my_saisie ,
            total_heure: SaisieTemps.sum_time_values(my_saisie),

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
            data_projects: data_projects
          )
      {:ok, socket , layout: {PmLoginWeb.LayoutView, "saisie_layout.html"}}
    end




  #fonction de tri par projet
    def handle_event("sort",_params , socket) do

      sorted_saisies = Enum.sort_by(socket.assigns.my_saisie, &(&1.project_title))
      {:noreply, assign(socket, my_saisie: sorted_saisies)}

    end



  #evenement qui ouvre la pop-up d'edition de saisie (modification)
    def handle_event("edit_entrie",%{"entrie_id" => entrie_id}, socket) do
      to_edit = SaisieTemps.get_entrie_by_id(String.to_integer(entrie_id)) #le saisie a modifier
      to_edit_project = Monitoring.get_project!(to_edit.project_id) #le projet correspondant au saisie
      task_edit_entrie = Monitoring.get_task!(to_edit.task_id) #la tache correspondant au siaise
      tasks = SaisieTemps.get_tasks_by_project(to_edit.project_id) #liste des taches
      {:noreply , socket|>assign(show_modal: true , entrie_to_edit:  to_edit , entrie_project: to_edit_project ,entrie_task: task_edit_entrie , tasks: tasks)}
    end


  #evenement qui ferme la pop-up d'edition
    def handle_event("close_edit_modal",_params, socket) do
      {:noreply , socket|>assign(show_modal: false )}
    end


  #fonction qui ecoute les changement d'etat des input de la formulaire d'edition des saisie
  #event sur la liste deroulante de projet
  #par defaut la liste le projet du saisie a modifier est deja selectioner , et la taches aussi
    def handle_event("project_change",params, socket) do

      #si cette condition est true alors la liste deroulante projet a changer d'etat c-a-d l'utilisateur essaye de modifier le projet
      if socket.assigns.entrie_project.id != String.to_integer(params["project_id"]) do
          {:noreply , socket|>assign(
            tasks: SaisieTemps.get_tasks_by_project(String.to_integer(params["project_id"])), #taches correspondant au projet selectionner
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
        my_saisie = SaisieTemps.get_saisie_by_user_by_date(socket.assigns.curr_user_id , socket.assigns.date_today)
        case  SaisieTemps.update_entrie(socket.assigns.entrie_to_edit ,%{"user_id"=> user_id , "task_id" => task_id ,"project_id" => project_id ,"time_value" => time_value , "libele" => libele}) do
          {:error , message}
            ->
               {:noreply ,
                socket
                 |>assign(my_saisie: my_saisie , total_heure: SaisieTemps.sum_time_values(my_saisie)  , show_modal: false)
                 |>put_flash(:error ,message)
              }
          _
            ->  {:noreply ,
                socket
                 |>assign(my_saisie: my_saisie , total_heure: SaisieTemps.sum_time_values(my_saisie)  , show_modal: false)
              }

        end



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
          my_saisie = SaisieTemps.get_saisie_by_user_by_date(socket.assigns.curr_user_id , socket.assigns.date_today)
          {:noreply , socket
          |> assign(
            my_saisie: my_saisie ,
            total_heure: SaisieTemps.sum_time_values(my_saisie)
          )}
        {:error , _} ->
          {:noreply , socket}
      end
    end



  #fonction qui gere la formulaire de navigation dans d'autre date
  #redirection et changeent de parametre de l'url
    def handle_event("navigate_to_other_date",%{"date" => date}, socket) do
      today = Utilities.parse_date_string(date)
      url = Routes.saisie_temps_path(socket, :index_saisie , date: Utilities.parse_date_to_html(today))
      {:noreply ,
        socket
        |>redirect(to: url)
      }

    end


    def render(assigns) do
      PmLoginWeb.SaisieTempsView.render("saisie_page.html" , assigns)
    end

end
