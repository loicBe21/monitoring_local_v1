defmodule PmLoginWeb.LiveComponent.LaunchModalLiveComponent do
  use Phoenix.LiveComponent
  import Phoenix.HTML.Form
  import PmLoginWeb.ErrorHelpers

  @defaults %{
    left_button: "Cancel",
    left_button_action: nil,
    left_button_param: nil,
    right_button: "OK",
    right_button_action: nil,
    right_button_param: nil
  }






 def mount(socket) do
    {:ok, socket}
 end

  def update(%{id: _id} = assigns, socket) do
    {:ok, assign(socket, Map.merge(@defaults, assigns))}
  end

  def handle_event(
        "left-button-click",
        _params,
        %{
          assigns: %{
            left_button_action: left_button_action,
            left_button_param: left_button_param
          }
        } = socket
      ) do
    send(
      self(),
      {__MODULE__, :button_clicked, %{action: left_button_action, param: left_button_param}}
    )

    {:noreply, socket}
  end

 def render(assigns) do
  ~H"""
    <div id={"modal-#{@id}"}>
      <!-- Modal Background -->
      <div id="task_modal_container" class="modal-container" style={"visibility: #{ if @show_lauch_modal, do: "visible", else: "hidden" }; opacity: #{ if @show_lauch_modal, do: "1 !important", else: "0" };"}>
        <div class="modal-inner-container" phx-window-keydown="modal_close">
          <div class="modal-card-task">
            <div class="modal-inner-card">
            <p> task id : <%= @task_selected %> </p>
              <!-- Title -->
              <%= if @title != nil do %>
              <div class="modal-title">
                <%= @title %>
                <a href="#" class="x__close" style="position: relative; left: 0; margin-top: -5px" title="Fermer" phx-click="left-button-click" phx-target={"#modal-#{@id}"}><i class="bi bi-x"></i></a>
              </div>
              <% end %>

              <!-- Body -->
              <%= if @body != nil do %>
              <div class="modal-body">
                <%= @body %>
              </div>
              <% end %>

              <!-- MY FORM -->

              <form method="POST" phx-submit="submit_stop_record" >
                <div class="modal-body">

                    <div class="column">
                      <label class="zoom-out">Titre</label>
                      <input type="number" name="task_id" value={@task_selected} readonly>
                    </div>


                  <%= for launch_type <- @launch_types do %>
                    <div class="row">
                      <div class="column">
                        <label class="zoom-out"><%= launch_type.description %></label>
                        <input input type="radio" name="launch_id" value={launch_type.id}>
                      </div>
                    </div>
                  <% end %>
                  <input type="submit" value="ok">

                </div>
              </form>

            </div>
          </div>
        </div>

      </div>
    </div>

  """
 end


end
