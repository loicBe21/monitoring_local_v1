defmodule PmLoginWeb.SaisieTempsController do

  use PmLoginWeb, :controller
  alias Phoenix.LiveView
  alias  PmLogin.SaisieTemps
  alias PmLogin.SaisieTemps.TimeEntrie
  alias PmLogin.Utilities

 # def index(conn, _params) do
  #  LiveView.Controller.live_render(conn , PmLoginWeb.SaisieTemps.IndexLive ,session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
 # end
 # def index_admin(conn, _params) do
  #  LiveView.Controller.live_render(conn , PmLoginWeb.SaisieTemps.AdminIndexLive ,session: %{"curr_user_id" => get_session(conn, :curr_user_id)}, router: PmLoginWeb.Router)
 # end

 # def details(conn, %{"id" => id , "date" => date }) do
   # LiveView.Controller.live_render(conn , PmLoginWeb.SaisieTemps.SaisieDetailsLive ,session: %{"curr_user_id" => get_session(conn, :curr_user_id) , "user_id" => id , "date" => date}, router: PmLoginWeb.Router)
 # end

 #url details saisie
  def details1(conn, %{"id" => id , "date" => date , "start_date" => start_date , "end_date" => end_date , "status" => status , "right" => right , "username" => username }) do
    LiveView.Controller.live_render(conn , PmLoginWeb.SaisieTemps.SaisieTempsDetailLive ,session: %{"curr_user_id" => get_session(conn, :curr_user_id) , "user_id" => id , "date" => date , "start_date" => start_date , "end_date" => end_date , "status" => status , "right" => right , "username" => username}, router: PmLoginWeb.Router)
  end

  #url index saisie
  def index_saisie(conn, %{"date" => date}) do
    LiveView.Controller.live_render(conn , PmLoginWeb.SaisieTemps.SaisieIndexLive ,session: %{"curr_user_id" => get_session(conn, :curr_user_id) , "date" => date}, router: PmLoginWeb.Router)
  end

  #url siaise de temps espace admin
  def index_admin1(conn, %{"start_date" => start_date , "end_date" => end_date , "status" => status , "right" => right , "username" => username}) do
    LiveView.Controller.live_render(conn , PmLoginWeb.SaisieTemps.SaisieAdminPageLive ,session: %{"curr_user_id" => get_session(conn, :curr_user_id),"start_date" => start_date , "end_date" => end_date , "status" => status , "right" => right , "username" => username}, router: PmLoginWeb.Router)
  end

  #creation d'une ligne de saisie

  #appeler par ajax
  def create(conn, %{"date" => date_entries, "user_id" => user_id, "project_id" => project_id ,  "task" => task_id, "labels" => libele, "hours" => time_value}) do

    #creer une map avec les parametres de l'url
    attrs = %{"date_entries" => Utilities.date_to_datetime(Utilities.parse_date_string(date_entries)), "user_id" => user_id, "task_id" => task_id, "project_id" => project_id, "libele" => libele, "time_value" => time_value}
     case SaisieTemps.save_entries(attrs) do
      {:ok, _time_entry} ->
        conn
        |> put_status(:ok)
        |> json(%{status: "success"})

      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", message: message})
      end
  end





end
