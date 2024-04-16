defmodule PmLoginWeb.LiveComponent.ConfirmValidationSaisieComponent do
use Phoenix.LiveComponent


    # render modal
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div id= "confirmation de validation">
      <!-- Modal Background -->
      <div id="new_modal_container" class="modal-container" style={"visibility: #{if @show_modal, do: "visible", else: "hidden"}; opacity: #{if @show_modal, do: "1 !important", else: "0"};"}>
        <div class="modal-inner-container">
          <div class="modal-card">
            <div class="modal-inner-card">
              <!-- Title -->
              <%= if @title != nil do %>
                <div class="modal-title">
                  <%= @title %>
                </div>
              <% end %>

              <!-- Body -->
              <%= if @body != nil do %>
                <div class="modal-body">
                  <p>Utilsateur : <%= @saisie_username %></p>
                  <p>Totale heure(s) : <%= @time_value %></p>
                  <p>date: <%= @date %></p>
                </div>
              <% end %>

              <!-- Buttons -->
              <div class="modal-buttons">
                <!-- Left Button -->
                <button class="btn btn-lg btn-default left-button"
                        type="button"
                        phx-click = "cancel_validation"

                      >
                  <div>
                    Annuler
                  </div>
                </button>
                <!-- Right Button -->
                <button class="btn btn-lg btn-primary right-button"
                        type="button" ,
                        phx-click = "validate_saise"
                         phx-value-user_id ={@user_id} phx-value-date= {@date}  phx-value-time_value = {@time_value} phx-value-user_validator_id = {@user_validator}
                       }>
                  <div>
                    Confirmer
                  </div>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

end
