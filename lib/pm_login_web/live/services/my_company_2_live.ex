defmodule PmLoginWeb.Services.MyCompany2Live do
  use Phoenix.LiveView
  alias PmLogin.Services

  def mount(_params, %{"curr_user_id"=>curr_user_id}, socket) do
    Services.subscribe()
    active_client = Services.get_active_client_from_userid!(curr_user_id)
    layout =
      case Services.get_active_client_from_userid!(curr_user_id).rights_clients_id do
        1 -> {PmLoginWeb.LayoutView, "active_client_admin_layout_live.html"}
        2 -> {PmLoginWeb.LayoutView, "active_client_demandeur_layout_live.html"}
        3 -> {PmLoginWeb.LayoutView, "active_client_utilisateur_layout_live.html"}
        _ -> {}
      end
    {:ok,
       socket
       |> assign(curr_user_id: curr_user_id,show_notif: false, notifs: Services.list_my_notifications_with_limit(curr_user_id, 4), active_client: active_client),

       layout: layout
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

  def render(assigns) do
   PmLoginWeb.CompanyView.render("my_company.html", assigns)
  end

end