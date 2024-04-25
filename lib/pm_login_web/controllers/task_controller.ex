defmodule PmLoginWeb.TaskController do
  use PmLoginWeb, :controller

  alias PmLogin.Monitoring
  alias PmLogin.Monitoring.Task
  alias PmLogin.Login
  alias Phoenix.LiveView
  alias PmLogin.SaisieTemps

  # def index(conn, _params) do
  #   tasks = Monitoring.list_tasks()
  #   render(conn, "index.html", tasks: tasks)
  # end

  # def new(conn, _params) do
  #   changeset = Monitoring.change_task(%Task{})
  #   render(conn, "new.html", changeset: changeset)
  # end

  def create(conn, %{"task" => task_params}) do
    case Monitoring.create_task(task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Tâche créée.")
        |> redirect(to: Routes.task_path(conn, :show, task))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  # def show(conn, %{"id" => id}) do
  #   task = Monitoring.get_task!(id)
  #   render(conn, "show.html", task: task)
  # end

  # def edit(conn, %{"id" => id}) do
  #   task = Monitoring.get_task!(id)
  #   changeset = Monitoring.change_task(task)
  #   render(conn, "edit.html", task: task, changeset: changeset)
  # end



  #l url de chargement de la page de details taches
  def show(conn, %{"id" => id}) do

    if Login.is_connected?(conn) do
      LiveView.Controller.live_render(conn, PmLoginWeb.Task.ShowLive1, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "id" => id}, router: PmLoginWeb.Router)
      # cond do
      #   Login.is_admin?(conn) or Login.is_attributor?(conn) ->
      #     changeset = Monitoring.change_project(%Project{})
      #     ac_list = Services.list_active_clients
      #     ac_ids = Enum.map(ac_list, fn(%ActiveClient{} = ac) -> {ac.user.username, ac.id} end )
      #     # render(conn, "new.html", changeset: changeset, ac_ids: ac_ids, layout: {PmLoginWeb.LayoutView, "admin_layout.html"})
      #     LiveView.Controller.live_render(conn, PmLoginWeb.Project.NewLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "changeset" => changeset, "ac_ids" => ac_ids}, router: PmLoginWeb.Router)
      #   true ->
      #     conn
      #       |> Login.not_admin_redirection
      # end
    else
      conn
      |> Login.not_connected_redirection
    end

  end

  def task_need_validation(conn , %{"id" => id}) do
    if Login.is_connected?(conn) do
      LiveView.Controller.live_render(conn, PmLoginWeb.Task.TaskNeedValidationLive, session: %{"curr_user_id" => get_session(conn, :curr_user_id), "id" => id}, router: PmLoginWeb.Router)
    else
      conn
      |> Login.not_connected_redirection
    end


  end

  def update(conn, %{"id" => id, "task" => task_params}) do
    task = Monitoring.get_task!(id)

    case Monitoring.update_task(task, task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Tâche mise à jour.")
        |> redirect(to: Routes.task_path(conn, :show, task))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", task: task, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    task = Monitoring.get_task!(id)
    {:ok, _task} = Monitoring.delete_task(task)

    conn
    |> put_flash(:info, "Tâche supprimée.")
    |> redirect(to: Routes.task_path(conn, :index))
  end


 #api qui retourne les taches et les details sur le client d'une projet
 def task_by_project(conn, %{"project_id" => project_id}) do
    tasks = SaisieTemps.get_tasks_by_project(String.to_integer(project_id))
    client_details = SaisieTemps.get_client_details_by_rpoject(String.to_integer(project_id))
    json(conn, %{tasks: tasks, client_details: client_details})
  end




end
