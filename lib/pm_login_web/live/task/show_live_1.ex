defmodule PmLoginWeb.Task.ShowLive1 do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLogin.Monitoring
  alias PmLogin.Login
  alias PmLogin.Login.User
  alias PmLogin.Monitoring.Task
  alias PmLogin.Kanban
  alias PmLogin.Kanban.Card
  alias PmLogin.SaisieTemps
  alias PmLoginWeb.Router.Helpers, as: Routes

 def mount(_params, %{"curr_user_id" => curr_user_id, "id" => id}, socket) do
    Monitoring.subscribe()
    Services.subscribe()
    Services.subscribe_to_request_topic()
    user_object = Login.get_user!(curr_user_id)
    right_object = Login.get_right!(user_object.right_id)
    task = Monitoring.get_task_by_id(id)
    task_estimation_in_hours = task.estimated_duration / 60
    is_mother_task =
      case task.parent_id do
      nil -> false
      _ -> true
    end

    project = Monitoring.get_project!(task.project_id)
    board = Kanban.get_board!(project.board_id)
    tasks_history = Monitoring.list_history_tasks_by_id(id)
     # pour les afficher les admin dans la liste deroulante
    admin_users = Login.list_admins_users()
    list_admins = Enum.map(admin_users, fn %User{} = a -> {a.username, a.id} end)

    contributors = Login.list_contributors()
    list_contributors = Enum.map(contributors, fn %User{} = p -> {p.username, p.id} end)

    attributors = Login.list_attributors()
    list_attributors = Enum.map(attributors, fn %User{} = a -> {a.username, a.id} end)

    list_for_admin = list_admins ++ list_attributors ++ list_contributors
    list_for_attributeur = list_attributors ++ list_contributors

    IO.inspect list_for_admin

    secondary_changeset =
    case Monitoring.is_contributor?(curr_user_id) do
      false ->
        #task_changeset = Monitoring.change_task_2(%Task{})
        Monitoring.change_task_2(%Task{})

       true ->
        #task_changeset = Monitoring.change_task_contributor(%Task{})
        Monitoring.change_task_contributor(%Task{})
    end

    client_details = SaisieTemps.get_client_details_by_rpoject(task.project_id)
    card = Monitoring.get_card_by_task_id(task.id)
    current_contributor = Login.get_user!(card.task.contributor_id)
    time_spent = SaisieTemps.get_time_spent_per_task(task.id)
    layout =
      case Login.get_user!(curr_user_id).right_id do
        # 1 -> {PmLoginWeb.LayoutView, "board_layout_live.html"}
        # 2 -> {PmLoginWeb.LayoutView, "attributor_board_live.html"}
        # 3 -> {PmLoginWeb.LayoutView, "contributor_board_live.html"}
        # _ -> {}
        1 -> {PmLoginWeb.LayoutView, "admin_layout_live.html"}
        2 -> {PmLoginWeb.LayoutView, "attributor_layout_live.html"}
        3 -> {PmLoginWeb.LayoutView, "contributor_layout_live.html"}
        _ -> {}
      end

    socket =
      socket
      |> assign(
        curr_user_id: curr_user_id,
        task: task,
        notifs: Services.list_my_notifications_with_limit(curr_user_id, 4),
        attributors: list_attributors,
        contributors: list_contributors,
        list_admins: list_admins,
        is_admin: Monitoring.is_admin?(curr_user_id),
        is_contributor: Monitoring.is_contributor?(curr_user_id),
        is_attributor: Monitoring.is_attributor?(curr_user_id),
        tasks_history: tasks_history,
        secondary_changeset: secondary_changeset,
        show_notif: false,
        show_secondary: false,
        board: board,
        showing_primaries: true,
        right_object: right_object,
        is_mother_task: is_mother_task,
        project: project,
        client: client_details,
        card: card ,
        list_for_admin:   Enum.sort_by(list_for_admin, &(&1)),
        list_for_attributeur:  Enum.sort_by(list_for_attributeur, &(&1)) ,
        current_contributor: current_contributor ,
        time_spent:  time_spent ,
        task_estimation_in_hours: task_estimation_in_hours
      )

    {:ok, socket, layout: layout}
 end


 def handle_event("show_modal" , _params , socket) do
  {:noreply ,  socket|>assign(show_secondary: true)}
 end

 def handle_event("close_modal",_params, socket) do
  {:noreply ,  socket|>assign(show_secondary: false)}
 end

 def handle_info({PmLoginWeb.LiveComponent.SecondaryModalLive1, :button_clicked, %{action: "cancel-secondary"}}, socket) do
    {:noreply,
     assign(socket, show_secondary: false, secondary_changeset: Monitoring.change_task(%Task{}))}
 end


  def handle_event("submit_secondary", %{"task" => params}, socket) do
    IO.inspect params
    hour = String.to_integer(params["hour"])
    minutes = String.to_integer(params["minutes"])

    total_minutes = hour * 60 + minutes

    # Ajouter la durée estimée dans le map
    params = Map.put(params, "estimated_duration", total_minutes)

    parent_task = Monitoring.get_task!(params["parent_id"])
    # IO.inspect parent_task

    parent_params =
      cond do
        is_nil(parent_task.contributor_id) and is_nil(params["contributor_id"]) ->
          %{
            "attributor_id" => socket.assigns.curr_user_id,
            "priority_id" => parent_task.priority_id
          }

        not is_nil(params["contributor_id"]) ->
          %{
            "attributor_id" => socket.assigns.curr_user_id,
            "contributor_id" => params["contributor_id"],
            "priority_id" => parent_task.priority_id
          }

        true ->
          %{
            "attributor_id" => socket.assigns.curr_user_id,
            "contributor_id" => parent_task.contributor_id,
            "priority_id" => parent_task.priority_id
          }
      end

    # IO.puts "parent params"
    # IO.inspect parent_params

    # IO.puts "output"
    op_params = params |> Map.merge(parent_params)
    # IO.inspect op_params

     url =  Routes.task_path(socket , :show , parent_task.id)
    case Monitoring.create_secondary_task(op_params) do
      {:ok, task} ->
        Monitoring.substract_mother_task_progression_when_creating_child(task)
        this_board = socket.assigns.board
        [head | _] = this_board.stages
        Kanban.create_card(%{name: task.title, stage_id: head.id, task_id: task.id})
        # NOTIFY ATTRIBUTOR THAT A SECONDARY TASK HAS BEEN CREATED
        if not is_nil(task.contributor_id) do
          Services.send_notif_to_one(
            task.attributor_id,
            task.contributor_id,
            "#{Login.get_user!(task.contributor_id).username} a été assigné à la sous-tâche #{task.title} du projet #{Monitoring.get_project!(task.project_id).title} par #{Login.get_user!(task.attributor_id).username}",
            6
          )

          Services.send_notifs_to_admins(
            task.attributor_id,
            "#{Login.get_user!(task.contributor_id).username} a été assigné à la sous-tâche #{task.title} du projet #{Monitoring.get_project!(task.project_id).title} par #{Login.get_user!(task.attributor_id).username}",
            6
          )
        end

        {:noreply,
         socket
         |> redirect(to: url)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, secondary_changeset: changeset)}
    end
  end


  def handle_info({Monitoring, [:mother, :updated], _}, socket) do
    board_id = socket.assigns.board.id

    board = Kanban.get_board!(board_id)

    new_stages =
      case socket.assigns.showing_primaries do
        true ->
          board.stages
          |> Enum.map(fn %Kanban.Stage{} = stage ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
          end)

        _ ->
          board.stages
          |> Enum.map(fn %Kanban.Stage{} = stage ->
            struct(stage, cards: cards_list_secondary_tasks(stage.cards))
          end)
      end

    # current_board = Kanban.get_board!(socket.assigns.board.id)
    new_board = struct(board, stages: new_stages)

    {:noreply, assign(socket, board: new_board)}
  end

  def cards_list_primary_tasks(old_list) do
    new_list = for card <- old_list do
                  day_blocked = if (card.task.status_id == 2) and (not is_nil(Monitoring.get_last_task_history(card.task.id))) do
                                  Date.diff(Date.utc_today(),Monitoring.get_last_task_history(card.task.id).inserted_at |> NaiveDateTime.to_date())
                                else
                                  0
                                end
                  card |> Map.from_struct() |> Map.put_new(:day_blocked ,day_blocked)
                end
    new_list |> Enum.filter(fn card -> is_nil(card.task.parent_id) end) |> Enum.filter(fn card -> card.task.status_id > 0 end)
  end

  def cards_list_secondary_tasks(old_list) do
    new_list = for card <- old_list do
                  day_blocked = if (card.task.status_id == 2) and (not is_nil(Monitoring.get_last_task_history(card.task.id))) do
                                  Date.diff(Date.utc_today(),Monitoring.get_last_task_history(card.task.id).inserted_at |> NaiveDateTime.to_date())
                                else
                                  0
                                end
                  Map.from_struct(card) |> Map.put(:day_blocked ,day_blocked)
                end
    new_list |> Enum.filter(fn card -> not is_nil(card.task.parent_id) end) |> Enum.filter(fn card -> card.task.status_id > 0 end)
  end


   def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length

    {:noreply,
     socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end

   def handle_info({Monitoring, [:task, :updated], _}, socket) do
    {:noreply , socket}
   end

  def handle_event("modify_task" , params , socket) do
    IO.inspect params
    task =  Monitoring.get_task!(socket.assigns.task.id)


    contributor_id = case params["assigned_person"] do
      nil -> task.contributor_id
      _ -> params["assigned_person"]
    end
    date_start =  case params["start_date"] do
      nil -> task.date_start
      _ -> params["start_date"]
    end
    deadline = case params["due_date"] do
      nil -> task.deadline
      _ -> params["due_date"]
    end
    estimated_duration = case params["original_estimate"] do
      nil -> task.estimated_duration
      _ ->
        val =  PmLogin.Utilities.format_decimal(params["original_estimate"])
        min_val = String.to_float(val) * 60.0
        rounded_val  = Float.round(min_val)
        trunc(rounded_val)

    end

    attrs = %{
      "title"  => params["task_title"] ,
      "description" => params["task_description"] ,
      "contributor_id" => contributor_id ,
      "progression" => params["progress"] ,
      "date_start" => date_start ,
      #"date_end" => params["due_date"] ,
      "estimated_duration" => estimated_duration,
      "priority_id" => params["priority_id"] ,
      "status_id" => params["status_id"] ,
      "project_id" => params["pro_id"] ,
      "deadline" => deadline


    }
    IO.inspect attrs
    task_changeset =  Task.update_changeset(socket.assigns.task , attrs)
    IO.inspect task_changeset
    url =  Routes.task_path(socket , :show , task.id)
    case Monitoring.update_task(task, attrs) do
      {:ok, updated_task} ->
        current_card = Monitoring.get_card_by_task_id(task.id)
        IO.inspect current_card
        IO.inspect updated_task

       IO.inspect  Kanban.update_card(current_card, %{name: updated_task.title})
        # IO.inspect task
        # IO.inspect attrs
        {:ok, updated_task} |> Monitoring.broadcast_updated_task()

        # IO.inspect {:ok, task}
        # IO.inspect {:ok, updated_task}

        if is_nil(task.contributor_id) and not is_nil(updated_task.contributor_id) do
          Services.send_notif_to_one(
            updated_task.attributor_id,
            updated_task.contributor_id,
            "#{Login.get_user!(updated_task.contributor_id).username} a été assigné à la tâche #{updated_task.title} par #{Login.get_user!(updated_task.attributor_id).username}",
            6
          )

          Services.send_notifs_to_admins(
            updated_task.attributor_id,
            "#{Login.get_user!(updated_task.contributor_id).username} a été assigné à la tâche #{updated_task.title} par #{Login.get_user!(updated_task.attributor_id).username}",
            6
          )
        end

        {:noreply ,  socket|> redirect(to: url)}
      {:error, %Ecto.Changeset{} = changeset} ->
        # IO.inspect changeset
        # IO.inspect changeset.errors
        {:noreply, socket |> put_flash(:error , "erreur !")}
    end


  end





 def render(assigns) do
    PmLoginWeb.TaskView.render("show1.html", assigns)
 end



end
