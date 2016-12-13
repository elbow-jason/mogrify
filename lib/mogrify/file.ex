defmodule Mogrify.File do
  alias Mogrify.Image

  @doc """
  Identifies whether or not a file exists, dangerously.
  """
  def open!(path) do
    path = Path.expand(path)
    if File.regular?(path) do
      %Image{path: path, ext: Path.extname(path)}
    else
      raise(File.Error)
    end
  end

  @doc """
  Identifies whether or not a file exists, safely.
  """
  def open(path) do
    path = Path.expand(path)
    if File.regular?(path) do
      {:ok, %Image{path: path, ext: Path.extname(path)}}
    else
      {:error, :enoent}
    end
  end

  @doc """
  Saves
  """
  def save(%Image{} = img, opts \\ []) do
    output_path = output_path_for(img, opts)
    img
    |> Mogrify.Command.arguments_for_saving(output_path)
    |> Mogrify.Command.mogrify
    Image.after_command(img, output_path)
  end

  def create(%Image{} = img, opts \\ []) do
    output_path = output_path_for(img, opts)
    args = Mogrify.Command.arguments_for_creating(img, output_path)
    Mogrify.Command.convert(args)
    Image.after_command(img, output_path)
  end


  @doc """
  Makes a copy of original image
  """
  def copy(image) do
    temp = temporary_path(image)
    File.cp!(image.path, temp)
    Map.put(image, :path, temp)
  end

  def temporary_path(%{dirty: %{path: dirty_path}} = _image) do
    do_temporary_path(dirty_path)
  end
  def temporary_path(%{path: path} = _image) do
    do_temporary_path(path)
  end

  defp do_temporary_path(path) do
    name = Path.basename(path)
    random = :crypto.rand_uniform(100_000, 999_999)
    Path.join(System.tmp_dir, "#{random}-#{name}")
  end

  def output_path_for(%Image{} = image, opts) do
    if Keyword.get(opts, :in_place) do
      image.path
    else
      Keyword.get(opts, :path, temporary_path(image))
    end
  end


end
