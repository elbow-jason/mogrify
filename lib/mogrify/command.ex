defmodule Mogrify.Command do
  alias Mogrify.Image

  @verbose_regex ~r/\b(?<animated>\[0])? (?<format>\S+) (?<width>\d+)x(?<height>\d+)/

  defp dev_null do
    case :os.type do
      {:win32, _} -> "NUL"
      _ -> "/dev/null"
    end
  end

  def normalize_arguments({option, params}) when params |> is_binary do
    case {option, params} do
      {:image_operator, params} -> [params]
      {"+" <> option, params}   -> ["+" <> option, params]
      {"-" <> option, params}   -> ["-" <> option, params]
      {option, params}          -> ["-" <> to_string(option), params]
    end
  end
  def normalize_arguments({option, params}) do
    normalize_arguments({option, to_string(params)})
  end


  def normalize_verbose_term({option, params}) do
    case {option, params} do
      {"animated", "[0]"} -> {:animated, true}
      {"animated",    ""} -> {:animated, false}
      {"width", value}    -> {:width, String.to_integer(value)}
      {"height", value}   -> {:height, String.to_integer(value)}
      {key, value}        -> {String.to_atom(key), String.downcase(value)}
    end
  end

  def mogrify(args) do
    case System.cmd("mogrify", args, stderr_to_stdout: true) do
      {output, 0}   -> {:ok, output}
      {err, _code}  -> {:error, err}
    end
  end

  def convert(args) do
    case System.cmd("convert", args, stderr_to_stdout: true) do
      {output, 0}   -> {:ok, output}
      {err, _code}  -> {:error, err}
    end
  end

  def verbose(%Image{path: path} = img) do
    {:ok, output} =
      ~w(-verbose -write #{dev_null} #{String.replace(path, " ", "\\ ")})
      |> mogrify

    info =
      @verbose_regex
      |> Regex.named_captures(output)
      |> Enum.map(&normalize_verbose_term/1)
      |> Enum.into(%{})
      |> Image.from_map
      |> Image.put_frame_count(output)
    Map.merge(img, info)
  end

  def arguments_for_saving(%Image{path: img_path} = img, path) do
    arguments(img) ++ ~w(-write #{path} #{img_path |> safe_name})
  end

  def arguments_for_creating(%Image{} = img, path) do
    paths = [
      Path.dirname(path),
      img.path |> Path.basename |> safe_name,
    ]
    arguments(img) ++ (paths |> Path.join |> List.wrap)
  end

  defp arguments(%Image{operations: ops}) do
    Enum.flat_map(ops, &normalize_arguments/1)
  end

  defp safe_name(path) do
    String.replace(path, " ", "\\ ")
  end

  def image_after_command(%Image{} = image, output_path) do
    %{image | path: output_path,
              ext: Path.extname(output_path),
              format: Map.get(image.dirty, :format, image.format),
              operations: [],
              dirty: %{}}
  end


end
