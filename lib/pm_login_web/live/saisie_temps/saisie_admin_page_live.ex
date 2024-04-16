defmodule PmLoginWeb.SaisieTemps.SaisieAdminPageLive do


  #liveView qui charge la page index saisie de temps espace admin
  #Routes => get "/saisie_index" , SaisieTempsController , :index_admin1
  #Controller => SaisieTempsController.index_admin1
  #Templates => template/saisie_temps/saisie_admin_page.html

  use Phoenix.LiveView
    alias PmLogin.Services
    alias PmLogin.Utilities
    alias PmLogin.Login
    alias PmLogin.SaisieTemps
    alias PmLoginWeb.Router.Helpers, as: Routes

  def mount(_params, %{"curr_user_id" => curr_user_id ,"start_date" => start_date , "end_date" => end_date , "status" => status , "right" => right , "username" => username}, socket) do

    today = Date.utc_today()
    current_user =  Login.get_user!(curr_user_id)
    projects = SaisieTemps.get_projects_avalable_for_saisie
    start_date = Utilities.parse_date_string(start_date)
    end_date = Utilities.parse_date_string(end_date)
    right = String.to_integer(right)
    status = String.to_integer(status)
    username =  username
    right_list = right_list()
    status_list = status_list()
    right_selected = Enum.find(right_list(), fn map -> map.id == right end)
    status_selected = Enum.find(status_list(), fn map -> map.id == status end)
    IO.inspect username

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
          saisie_data:  SaisieTemps.get_resum_saisie_by_params(start_date, end_date, right, status, username)|> Enum.filter(fn map -> map.user_id != current_user.id end),
          sorted_by_utilisateur:  false ,
          sorted_by_droit: false ,
          sorted_by_time_value: false ,
          sorted_by_status: false ,
          start_date: start_date ,
          end_date: end_date ,
          right: right ,
          status: status ,
          status_string_format: status_to_string(status) ,
          right_string_format: right_to_string(right) ,
          right_list: right_list ,
          right_selected: right_selected ,
          status_list: status_list ,
          status_selected: status_selected ,
          show_notif: false ,
          username: username ,
          #pour la popup de confirmation
          show_modal: false ,
          date: nil ,
          time_value: nil ,
          user_id: nil ,
          saisie_username: nil

        )
    {:ok, socket , layout: {PmLoginWeb.LayoutView, "saisie_layout.html"}}
  end



  #validation des saisie
  def handle_event("validate_saise",params, socket) do
    IO.puts "makato ve aloha"
    IO.inspect params
    start_date = socket.assigns.start_date
    end_date = socket.assigns.end_date
    right = socket.assigns.right
    status = socket.assigns.status
    username = socket.assigns.username
    case SaisieTemps.save_saisie_validee(params) do
      {:ok ,_}
        ->

          {:noreply , socket
         |>assign(saisie_data: SaisieTemps.get_resum_saisie_by_params(start_date, end_date , right , status , username) , show_modal: false)
         }
        {:error , message}
        ->  {:noreply , socket
         |> clear_flash()
         |>put_flash(:error , message)}
    end



  end

  def handle_event("sort_by_utilisateur" , _params , socket) do

    case socket.assigns.sorted_by_utilisateur do
      true -> {:noreply , socket |>
      assign(
        saisie_data: Enum.sort_by(socket.assigns.saisie_data , &(&1.username) , :desc),
        sorted_by_utilisateur: false
      )

      }
       _ -> {:noreply , socket |>
      assign(
        saisie_data: Enum.sort_by(socket.assigns.saisie_data, &(&1.username) ),
        sorted_by_utilisateur: true
      )

      }
    end
  end

  def handle_event("sort_by_droit" , _params , socket) do
    case socket.assigns.sorted_by_droit do
      true -> {:noreply , socket |>
      assign(
        saisie_data: Enum.sort_by(socket.assigns.saisie_data , &(&1.right_id) , :desc),
        sorted_by_droit: false
      )

      }
       _ -> {:noreply , socket |>
      assign(
        saisie_data: Enum.sort_by(socket.assigns.saisie_data, &(&1.right_id) ),
        sorted_by_droit: true
      )

      }
    end
  end


  def handle_event("sort_by_time_value", _params, socket) do
    case socket.assigns.sorted_by_time_value do
      true ->
        {:noreply, assign(socket, saisie_data: Enum.sort_by(socket.assigns.saisie_data, &Decimal.to_float(&1.time_value), :desc), sorted_by_time_value: false)}

      _ ->
        {:noreply, assign(socket, saisie_data: Enum.sort_by(socket.assigns.saisie_data, &Decimal.to_float(&1.time_value)), sorted_by_time_value: true)}
    end
  end

  def handle_event("sort_by_status", _params, socket) do
    case socket.assigns.sorted_by_status do
      true ->
        {:noreply, assign(socket, saisie_data: Enum.sort_by(socket.assigns.saisie_data, &(&1.status), :desc), sorted_by_status: false)}

      _ ->
        {:noreply, assign(socket, saisie_data: Enum.sort_by(socket.assigns.saisie_data, &(&1.status)), sorted_by_status: true)}
    end
  end

  def handle_event("do_filtre", %{"start_date" => start_date, "end_date" => end_date, "status" => status, "right" => right , "username" => username}, socket) do
    IO.inspect username
    start_date = Utilities.parse_date_string(start_date)
    end_date = Utilities.parse_date_string(end_date)
    right = String.to_integer(right)
    status = String.to_integer(status)
    url = Routes.saisie_temps_path(socket, :index_admin1, start_date: Utilities.parse_date_to_html(start_date), end_date: Utilities.parse_date_to_html(end_date), status: status, right: right , username: username)
    IO.puts "makato"
   # {:noreply, socket
   #   |>assign(
   #     start_date: start_date,
   #     end_date: end_date,
   #     right: right,
   #     status: status ,
   #     saisie_data: SaisieTemps.get_resum_saisie_by_params(start_date,end_date,right,status)
    #  )
    #} # Vous pouvez également renvoyer un événement push à l'interface utilisateur si nécessaire
    {:noreply ,
      socket
      |>redirect(to: url)
    }
  end


  defp status_to_string(status) do
    case status do
        #status validee
        1 ->
          " Validé "
        #status non validee
        2 ->
          "  Non validé"
        _ ->
          "Tous "

      end

  end

  defp right_to_string(right_id) do
   case right_id do
        #tous profil confondue
        0 ->
          "Tous"
        #only admin
        1 ->
          "Admin"
        2 ->
        #only attributeur
          "Attributeur"
        3 ->
        #only contributteur
          "Contributeur"
        _ ->
          ""
    end
  end


  defp right_list do
    [
      %{id: 0 , right: "Tous"} ,
      %{id: 1 , right: "Admin"} ,
      %{id: 2 , right: "Attributeur"} ,
      %{id: 3 , right: "Contributeur"}
    ]
  end

   defp status_list do
    [
      %{id: 0 , status: "Tous"} ,
      %{id: 1 , status: " validé"} ,
      %{id: 2 , status: "Non Validé"} ,

    ]
  end


  def handle_event("confirm_validation",params, socket) do
    IO.inspect params
    {:noreply ,
      socket |>
      assign(
        show_modal: true ,
        date: params["date"] ,
        time_value: params["time_value"] ,
        user_id: params["user_id"] ,
        saisie_username: params["saisie_username"]
      )
    }

  end

  def handle_event("cancel_validation",_params, socket) do
    {:noreply , socket |>assign(show_modal: false)}
  end




  def render(assigns) do
    PmLoginWeb.SaisieTempsView.render("saisie_admin_page.html" , assigns)
  end

end
