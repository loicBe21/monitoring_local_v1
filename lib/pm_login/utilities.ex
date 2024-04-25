defmodule PmLogin.Utilities do
  use Phoenix.HTML
  import PmLoginWeb.Gettext
  import CSV
  alias PmLogin.Monitoring
  alias PmLogin.Login



 def local_gmt3 do
    NaiveDateTime.local_now
    |>NaiveDateTime.add(3)
  end


  def test do
    now = NaiveDateTime.local_now
    Calendar.strftime(now, "%d/%m/%Y %Hh %M")
  end

  def simple_date_format(naive_dt) do
    Calendar.strftime(naive_dt, "%d/%m/%Y")
  end

  def simple_date_format1(naive_dt) do
    Calendar.strftime(naive_dt, "%Y-%m-%d")
  end

  def simple_date_format_with_hours(naive_dt) do
    Calendar.strftime(naive_dt, "%d/%m/%Y, à %Hh %M")
  end

  def simple_date_format_with_hours_onboard(naive_dt) do
    Calendar.strftime(naive_dt, "%d/%m/%Y, %Hh %M")
  end

  def letters_date_format_with_hours(naive_dt) do

    Calendar.strftime(naive_dt,"%A %d %B %Y, %Hh %M",
       day_of_week_names: fn day_of_week ->
         {"Lundi", "Mardi", "Mercredi", "Jeudi",
         "Vendredi", "Samedi", "Dimanche"}
         |> elem(day_of_week - 1)
       end,
       month_names: fn month ->
         {"Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
         "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"}
         |> elem(month - 1)
       end
      )
  end

  def letters_date_format_with_only_month_and_hours(naive_dt) do

    Calendar.strftime(naive_dt,"%d %B %Y, %Hh %M",
       month_names: fn month ->
         {"Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
         "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"}
         |> elem(month - 1)
       end
      )
  end

  def my_datetime_select(form, field, opts \\ []) do

    now = NaiveDateTime.local_now()

    builder = fn b ->
      ~e"""
      <%= b.(:day, []) %><%= b.(:month, []) %><%= b.(:year, []) %>
      <%= b.(:hour, []) %> h : <%= b.(:minute, []) %> min
      """
    end

    day = [selected: now.day]

    month = [
      options: [
        {gettext("Janvier"), "1"},
        {gettext("Février"), "2"},
        {gettext("Mars"), "3"},
        {gettext("Avril"), "4"},
        {gettext("Mai"), "5"},
        {gettext("Juin"), "6"},
        {gettext("Juillet"), "7"},
        {gettext("Août"), "8"},
        {gettext("Septembre"), "9"},
        {gettext("Octobre"), "10"},
        {gettext("Novembre"), "11"},
        {gettext("Décembre"), "12"},
      ],
      selected: now.month
    ]

    year = [options: (now.year)..(now.year+10)]

    hour = [selected: now.hour]

    datetime_select(form, field, [builder: builder] ++ [month: month] ++ [year: year] ++ [day: day] ++ [hour: hour] ++ opts)
  end

  def letters_date_format(naive_dt) do

    Calendar.strftime(naive_dt,"%A %d %B %Y",
       day_of_week_names: fn day_of_week ->
         {"Lundi", "Mardi", "Mercredi", "Jeudi",
         "Vendredi", "Samedi", "Dimanche"}
         |> elem(day_of_week - 1)
       end,
       month_names: fn month ->
         {"Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
         "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"}
         |> elem(month - 1)
       end
      )
  end

  def letters_date_format_without_days(naive_dt) do

    Calendar.strftime(naive_dt,"%d %B %Y",
       month_names: fn month ->
         {"Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
         "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"}
         |> elem(month - 1)
       end
      )
  end

  def naive_to_datetime(naive) do
    {:ok, datetime} = DateTime.from_naive(naive, "Etc/UTC")
    datetime
  end

  def date_to_naive(date) do
    {:ok, naive} = {Date.to_erl(date),{0,0,0}} |> NaiveDateTime.from_erl
    naive
  end

  def date_to_datetime(date) do
    {:ok, naive} = {Date.to_erl(date),{0,0,0}} |> NaiveDateTime.from_erl
    naive_to_datetime(naive)
  end

  # def seconds_between_dates(dt1, dt2) do

  # end
  def days_to_seconds(days) do
    days * 86400
  end

  #PERIODIC TEST
  def next_end(start_date, days_period) do

    # IO.puts("Start date: #{start_date} | Period: #{days_period}")
    curr_next_end = NaiveDateTime.add(start_date, days_to_seconds(days_period))

    now = NaiveDateTime.local_now()

    # IO.puts("End : #{curr_next_end}")

    cond do

      NaiveDateTime.compare(now, start_date) == :lt -> start_date
      (NaiveDateTime.compare(now, start_date) == :gt or NaiveDateTime.compare(now, start_date) == :eq) and (NaiveDateTime.compare(now, curr_next_end) == :lt) -> curr_next_end
      NaiveDateTime.compare(now, curr_next_end) == :gt or NaiveDateTime.compare(now, curr_next_end) == :eq -> next_end(curr_next_end, days_period)

    end

  end

  def test_next_end(start_date, period, val) do

    curr_next_end = start_date + period
    IO.puts("Start date: #{start_date} | Period: #{period}")
    IO.puts("End : #{curr_next_end}")

    cond do
      start_date < val and val <= curr_next_end ->
        curr_next_end

      curr_next_end < val ->
        test_next_end(curr_next_end, period, val)
    end

  end




  defp to_csv_line(task) do
    if not is_nil(task.contributor_id) do
      [task.id , task.title , Monitoring.list_statuses_by_id(task.status_id).title , Login.list_contributors_users(task.contributor_id).username ,simple_date_format(task.date_start) , simple_date_format(task.deadline)]
    else
      [task.id , task.title , Monitoring.list_statuses_by_id(task.status_id).title , Login.list_contributors_users(task.attributor_id).username , simple_date_format(task.date_start) , simple_date_format(task.deadline)]

    end
  end

  defp fetch_data_for_csv(task_list) do
    headers = ["id", "description" , "status" , "user_id" , "date_start" , "date_end"]
    csvLines = Enum.map(task_list, &to_csv_line/1)
    real_data = [headers | csvLines]
    real_data
  end


  defp csv_content_generator(task_list) do
    task_list
    |> fetch_data_for_csv()
    |> CSV.encode
    |> Enum.to_list
    |> to_string
  end

  def export(task_list) do
    csv_content_generator(task_list)
  end


  #fonction qui cree une liste de map pour chaque ligne (rows) avec le cles donnes en parametre
  #dans columns
  #utile pour recuperer les resultat d'une requete sql
  def build_result(columns, rows) do
    new_columns = Enum.map(columns, &String.to_atom/1)

    rows
    |> Enum.map(fn row ->
      Enum.zip(new_columns, row)
      |> Enum.into(%{})
    end)
  end


  #parse string date to date elixir
  def parse_date_string(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> date
      {:error, _reason} -> nil
    end
  end


  #parse date to html date format
  #use to send date in request url
  def parse_date_to_html(date)  do
    Date.to_string(date)
  end

  #pars minute values to "hh:mm" format
 def parse_minutes_to_time(minutes) do
    hours = div(minutes, 60)
    remaining_minutes = rem(minutes, 60)
    "#{String.pad_leading("#{hours}", 2, "0")}h #{String.pad_leading("#{remaining_minutes}", 2, "0")} min"
  end




  def current_datetime(date) do
    {:ok, {year, month, day}} = Date.from_iso8601(date)
    {hour, min, sec} = NaiveDateTime.now() |> NaiveDateTime.to_time()

    NaiveDateTime.new(year, month, day, hour, min, sec)
  end


  #pars an date elixir format "yyyy - mm - dd" to french format "dd/mm/yyyy"
  def french_date_format_by_date(date) do
    #create naive dt by this date
    date_time_today = date_to_naive(date)
    #parse naive date to french date format
    simple_date_format(date_time_today)
  end


 #fonction de formatage d'une nombre donnée en un chaine decimal
  def format_decimal(value) when is_binary(value) do
    case Float.parse(value) do
      {val, _} when is_integer(val) ->
        "#{val}.0"
      {val, _} ->
        "#{val}"
      :error ->
        "La valeur n'est pas une décimale valide."
    end
  end









end
