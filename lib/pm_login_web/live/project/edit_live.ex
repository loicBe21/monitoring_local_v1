defmodule PmLoginWeb.Project.EditLive do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLogin.Login
  alias PmLogin.Login.User
  alias PmLogin.Services.Rights_clients
  alias PmLogin.Services.Company
  alias PmLogin.Services.ActiveClient
  def mount(_params, %{"curr_user_id"=>curr_user_id, "project" => project, "changeset" => changeset, "ac_ids" => ac_ids, "status" => status}, socket) do
    Services.subscribe()
    user_changeset = Login.change_user(%User{})
    companies = Services.list_companies()
    companies_ids = Enum.map(companies, fn(%Company{} = c) -> {c.name, c.id} end )
    {:ok,
       socket
       |> assign(changeset: changeset, status: status, ac_ids: ac_ids, project: project,curr_user_id: curr_user_id, show_notif: false, notifs: Services.list_my_notifications_with_limit(curr_user_id, 4),form: false , user_changeset: user_changeset , rights_clients: Enum.map(Services.list_rights_clients, fn %Rights_clients{} = r -> {r.name, r.id} end),companies_ids: companies_ids),
       layout: {PmLoginWeb.LayoutView, "admin_layout_live.html"}
       }
  end

  def handle_event("switch-notif", %{}, socket) do
    notifs_length = socket.assigns.notifs |> length
    curr_user_id = socket.assigns.curr_user_id
    switch = if socket.assigns.show_notif do
              ids = socket.assigns.notifs
                    |> Enum.filter(fn(x) -> !(x.seen) end)
                    |> Enum.map(fn(x) -> x.id  end)
              Services.put_seen_some_notifs(ids)
                false
              else
                true
             end
    {:noreply, socket |> assign(show_notif: switch, notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length))}
  end

  def handle_event("load-notifs", %{}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    notifs_length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length+4)) |> push_event("SpinTest", %{})}
  end

  def handle_event("cancel-notif", %{}, socket) do
    cancel = if socket.assigns.show_notif, do: false
    {:noreply, socket |> assign(show_notif: cancel)}
  end

  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end


  def handle_event("show-form", _params, socket), do: {:noreply, socket|>assign(form: true)}
  def handle_event("close-form", _params, socket), do: {:noreply, socket|>assign(form: false)}


   def handle_event("cancel-form", %{"key" => key}, socket) do
    case key do
      "Escape" ->
        {:noreply, socket |> assign(form: false)}
        _ ->
        {:noreply, socket}
    end
  end

  def handle_event("save-user", params, socket) do
    # IO.inspect(params["user"])

    case Login.create_user_from_project(params["user"]) do
      {:ok, user} ->
        Login.broadcast_user_creation({:ok, user})
        ac_params = %{"user_id" => user.id, "company_id" => params["user"]["company_id"], "rights_clients_id" => params["user"]["rights_clients_id"]}
        Services.create_active_client(ac_params)

        params = params["user"]
        {:noreply, socket |> put_flash(:info, "Le client #{params["username"]} a été créé!") |> assign(form: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(user_changeset: changeset)}
    end

  end

  def handle_info({Services, [:active_client, :created], _}, socket) do
    {:noreply, socket |> assign(ac_ids: Services.list_active_clients |> Enum.map(fn(%ActiveClient{} = ac) -> {ac.user.username, ac.id} end ))}
  end

  def render(assigns) do
   PmLoginWeb.ProjectView.render("edit.html", assigns)
  end
end
