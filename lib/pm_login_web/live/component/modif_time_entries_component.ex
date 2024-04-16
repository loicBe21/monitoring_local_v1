defmodule PmLoginWeb.LiveComponent.ModifTimeEntriesComponent do
  use Phoenix.LiveComponent
  import Phoenix.HTML.Form
  import PmLoginWeb.ErrorHelpers




 def render(assigns) do
  ~H"""

    <div id="edit_entrie"}>
      <!-- Modal Background -->
      <div id="task_modal_container" class="modal-container" style={"visibility: #{ if @show_modal, do: "visible", else: "hidden" }; opacity: #{ if @show_modal, do: "1 !important", else: "0" };"}>
        <div class="modal-inner-container" >
         <%= if @entrie != nil do %>
          <div class="modal-card-task">
            <div class="modal-inner-card">

              <!-- Title -->
              <%= if @title != nil do %>
              <div class="modal-title">
                <%= @title %>
                <a href="#" class="x__close" style="position: relative; left: 0; margin-top: -5px" title="Fermer" phx-click="close_edit_modal" ><i class="bi bi-x"></i></a>
              </div>
              <% end %>

              <!-- Body -->
              <%= if @body != nil do %>
              <div class="modal-body">
                <%= @body %>
              </div>
              <% end %>

              <!-- MY FORM -->

              <form method="POST" phx-submit="update_entrie" phx-change="project_change"  >
                <input type="hidden" name="id" value={@entrie.id}>
                <input type="hidden" name="user_id" value={@entrie.user_id}>
                <input type="hidden" name="date_entries" value ={@entrie.date_entries} >
                <div class="modal-body">
                  <div class="my_row">
                      <label class="zoom-out">Projet</label>
                      <select name="project_id"  >
                        <option value={@entrie_project.id}><%= @entrie_project.title %></option>
                         <%= for project <- @projects do %>
                            <%= if project.id != @entrie_project.id do %>
                            <option value={project.id}><%= project.title %></option>
                            <% end %>
                        <% end %>
                      </select>
                  </div>
                  <div class="my_row">
                      <label class="zoom-out">Tache</label>
                       <select name="task_id" >
                       <%= if @project_select_state  == true  do %>
                        <option value={@entrie_task.id}><%= @entrie_task.title %></option>
                       <% end %>
                         <%= for task <- @tasks do %>
                            <%= if task.id != @entrie_task.id do %>
                            <option value={task.id}><%= task.title %></option>
                            <% end %>

                        <% end %>
                      </select>
                  </div>
                  <div class="my_row">
                    <div class="my_col">
                      <label class="zoom-out">Libele</label>
                      <textarea  cols="50" rows="20" name="libele" value={@entrie.libele} style="width: 768px; height: 59px;" ><%= @entrie.libele %></textarea>
                    </div>
                  </div>
                  <div class="my_row">
                    <div class="my_col">
                      <label class="zoom-out">Temps</label>
                      <input type="number" id="decimal_input" name="time_value"  value={@entrie.time_value}>
                    </div>
                  </div>
                  <div class="my_row" style="margin-top: 20px;">
                    <div class="my_col">
                      <input type="submit" value="ok">
                    </div>
                  </div>


                </div>
              </form>

            </div>
          </div>
         <% end %>
        </div>

      </div>
    </div>

  """
 end


end
