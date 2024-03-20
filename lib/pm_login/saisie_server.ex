defmodule PmLogin.SaisieServer do
  alias PmLogin.Email
  use GenServer


  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end



  # Fonction d'initialisation du serveur
  def init(state) do
    # Démarre l'envoi de messages toutes les 10 secondes
    send_periodic_message()
    {:ok, state}
  end

  # Fonction pour envoyer un message toutes les 10 secondes
  defp send_periodic_message() do
    # Affiche un message dans la console

    naive_dt_now = NaiveDateTime.local_now()
     #IO.puts("Bonjour depuis le serveur ! Date et heure actuelles : #{naive_dt_now}")
    date = Date.utc_today() |> Date.to_iso8601()
    time = "16:03:00"
    date_time_to_start = date <> " " <> time |> NaiveDateTime.from_iso8601!()
    cond do
        naive_dt_now == date_time_to_start ->
          Email.mail_test()
          Process.send_after(self(), :send_message, 1000)
        true ->
          Process.send_after(self(), :send_message , 1000)

    end
    #Email.mail_test()
    # Planifie l'envoi du prochain message dans 10 secondes
    #Process.send_after(self(), :send_message, 10_000)
  end

  # Fonction pour gérer les messages envoyés au serveur
  def handle_info(:send_message, state) do
    # Envoie un nouveau message toutes les 10 secondes
    send_periodic_message()
    {:noreply, state}
  end

end
