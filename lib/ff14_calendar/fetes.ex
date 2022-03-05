defmodule FF14Calendar.Fetes do
  # Increment this each time the events change time/contents.
  @sequence 1

  @epoch_interval Timex.Duration.from_hours(68)
  @epoch_margin Timex.Duration.from_days(7)

  @sessions 12
  @session_interval Timex.Duration.from_hours(2)
  @session_length Timex.Duration.from_minutes(30)

  def calendar(now \\ DateTime.utc_now(), margin \\ @epoch_margin) do
    calendar(now, margin, margin)
  end

  def calendar(now, pre_margin, post_margin) do
    %ICalendar{events: events(now, pre_margin, post_margin)}
  end

  defp start_time, do: Timex.to_datetime(~N[2022-03-01 02:00:00], "America/Toronto")

  defp epochs, do: Stream.iterate({0, start_time()}, &step_time(&1, @epoch_interval))
  defp sessions(start), do: Stream.iterate({1, start}, &step_time(&1, @session_interval))
  defp step_time({n, dt}, interval), do: {n + 1, Timex.add(dt, interval)}

  defp nearby_epochs(now, pre_margin, post_margin) do
    min = Timex.subtract(now, pre_margin)
    max = Timex.add(now, post_margin)

    epochs()
    |> Stream.drop_while(fn {_, dt} -> before?(dt, min) end)
    |> Enum.take_while(fn {_, dt} -> before?(dt, max) end)
  end

  defp events(now, pre_margin, post_margin) do
    nearby_epochs(now, pre_margin, post_margin)
    |> Enum.flat_map(&events_for_epoch/1)
  end

  defp events_for_epoch({epoch, start}) do
    sessions(start)
    |> Enum.take(@sessions)
    |> Enum.map(&event_for_epoch(epoch, &1))
  end

  # Does dt2 come before dt1?
  defp before?(dt1, dt2) do
    Timex.compare(dt1, dt2) == -1
  end

  defp event_for_epoch(epoch, {session, start}) do
    start_time = Timex.add(start, Timex.Duration.from_hours(2 * (session - 1)))
    end_time = Timex.add(start_time, @session_length)

    %ICalendar.Event{
      summary: "Skyrise Celebration: Session #{session}/#{@sessions}",
      dtstart: start_time |> Timex.to_erl(),
      dtend: end_time |> Timex.to_erl(),
      description: "Firmament fête, epoch ##{epoch}, session number #{session} of #{@sessions}.",
      uid: generate_uid(epoch, session),
      sequence: @sequence
    }
  end

  defp generate_uid(epoch, session) do
    UUID.uuid3(:oid, "ff14-fetes-#{epoch}-#{session}")
  end
end
