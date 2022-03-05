defmodule Mix.Tasks.Ff14.Put do
  use Mix.Task
  require Logger

  @moduledoc false

  def run([url]) do
    Logger.configure_backend(:console, Application.get_env(:logger, :console))

    ensure_env("AWS_ACCESS_KEY_ID")
    ensure_env("AWS_SECRET_ACCESS_KEY")

    {:ok, _started} = Application.ensure_all_started(:timex)
    {:ok, _started} = Application.ensure_all_started(:ex_aws_s3)

    FF14Calendar.Fetes.calendar()
    |> ICalendar.to_ics(vendor: "FF14Calendar")
    |> s3_put(url)
  end

  def run(_) do
    Mix.raise("Usage: mix ff14.put s3://bucket/path")
  end

  defp s3_put(ics, url) do
    {bucket, path} = parse_url(url)

    ExAws.S3.put_object(bucket, path, ics)
    |> ExAws.request!()

    Logger.info("Uploaded #{byte_size(ics)} bytes to #{url}")

    ExAws.S3.put_object_acl(bucket, path, acl: :public_read)
    |> ExAws.request!()

    Logger.info("Set ACL for #{url} to public read-only.")
  end

  defp parse_url(url) do
    %URI{
      scheme: "s3",
      host: host,
      path: path,
      port: nil,
      query: nil,
      userinfo: nil,
      fragment: nil
    } = URI.parse(url)

    {host, path}
  end

  defp ensure_env(var) do
    case System.fetch_env(var) do
      {:ok, _} -> :ok
      :error -> Mix.raise("Environment variable #{var} must be set")
    end
  end
end
