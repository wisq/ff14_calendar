defmodule FetesTest do
  use ExUnit.Case
  alias FF14Calendar.Fetes
  alias ICalendar.Event

  @day 86400
  @week 7 * @day

  test "generates a calendar around now" do
    assert calendar = Fetes.calendar()

    # Get all event times:
    first = calendar.events |> List.first() |> Map.fetch!(:dtstart) |> erl_to_unix()
    last = calendar.events |> List.last() |> Map.fetch!(:dtstart) |> erl_to_unix()

    # First and last events are within 2 weeks ago / from now.
    assert now = DateTime.utc_now() |> DateTime.to_unix()
    assert first < now
    assert last > now
    assert_in_delta first, now, 2 * @week
    assert_in_delta last, now, 2 * @week
  end

  test "generates calendar around specific time" do
    assert calendar = Fetes.calendar(~U[2022-03-15 00:00:00Z])

    assert %Event{
             dtstart: {{2022, 3, 9}, {14, 0, 0}},
             dtend: {{2022, 3, 9}, {14, 30, 0}},
             summary: "Skyrise Celebration: Session 1/12",
             description: "Firmament fête, epoch #3, session number 1 of 12."
           } = calendar.events |> List.first()

    assert %Event{
             dtstart: {{2022, 3, 10}, {2, 0, 0}},
             dtend: {{2022, 3, 10}, {2, 30, 0}},
             summary: "Skyrise Celebration: Session 4/12",
             description: "Firmament fête, epoch #3, session number 4 of 12."
           } = calendar.events |> Enum.at(3)

    assert %Event{
             dtstart: {{2022, 3, 22}, {19, 0, 0}},
             dtend: {{2022, 3, 22}, {19, 30, 0}},
             summary: "Skyrise Celebration: Session 12/12",
             description: "Firmament fête, epoch #7, session number 12 of 12."
           } = calendar.events |> List.last()
  end

  defp erl_to_unix(erl_time) do
    erl_time
    |> NaiveDateTime.from_erl!()
    |> Timex.to_datetime("America/Toronto")
    |> DateTime.to_unix()
  end
end
