defmodule Mogrify do
  alias Mogrify.Image

  @dimensions_regex ~r/(\d+)x(\d+)/

  def save(%Image{} = image, opts \\ []) do
    Mogrify.File.save(image, opts)
  end

  def open!(path) when path |> is_binary do
    Mogrify.File.open!(path)
  end

  def open(path) when path |> is_binary do
    Mogrify.File.open(path)
  end

  def copy(%Image{} = image) do
    Mogrify.File.copy(image)
  end

  @doc """
  Converts the image to the image format you specify
  """
  def format(%Image{} = img, params) when params |> is_binary do
    fmt = String.downcase(params)
    path = Path.rootname(img.path, img.ext) <> "." <> fmt
    img
    |> Image.append_operation(:format, fmt)
    |> Image.update_dirty(:path, path)
    |> Image.update_dirty(:format, fmt)
  end

  @doc """
  Resizes the image with provided geometry
  """
  def resize(%Image{} = img, params) when params |> is_binary do
    img |> Image.append_operation(:resize, params)
  end

  @doc """
  Extends the image to the specified dimensions
  """
  def extent(%Image{} = img, params) when params |> is_binary do
    img |> Image.append_operation(:extent, params)
  end

  @doc """
  Sets the gravity of the image
  """

  def gravity(%Image{} = img, params) when params |> is_binary do
    img |> Image.append_operation(:gravity, params)
  end

  @doc """
  Resize the image to fit within the specified dimensions while retaining
  the original aspect ratio. Will only resize the image if it is larger than the
  specified dimensions. The resulting image may be shorter or narrower than specified
  in the smaller dimension but will not be larger than the specified values.
  """
  def resize_to_limit(%Image{} = img, params) when params |> is_binary do
    resize(img, "#{params}>")
  end

  @doc """
  Resize the image to fit within the specified dimensions while retaining
  the aspect ratio of the original image. If necessary, crop the image in the
  larger dimension.
  """
  def resize_to_fill(%Image{} = image, params) do
    [_, width, height] = Regex.run(@dimensions_regex, params)
    image = Mogrify.Command.verbose(image)
    {width, ""} = Float.parse width
    {height, ""} = Float.parse height
    cols = image.width
    rows = image.height

    if width != cols || height != rows do
      scale_x = width/cols #.to_f
      scale_y = height/rows #.to_f
      larger_scale = max(scale_x, scale_y)
      cols = (larger_scale * (cols + 0.5)) |> Float.round
      rows = (larger_scale * (rows + 0.5)) |> Float.round
      image = resize image, (if scale_x >= scale_y, do: "#{cols}", else: "x#{rows}")

      if width != cols || height != rows do
        extent(image, params)
      else
        image
      end
    else
      image
    end
  end

  def auto_orient(%Image{} = img) do
    img |> Image.append_operation(:"auto-orient", nil)
  end

  def canvas(%Image{} = img, color) do
    image_operator(img, "xc:#{color}")
  end

  def custom(%Image{} = img, key, value \\ nil) do
    img |> Image.append_operation(key, value)
  end

  def image_operator(%Image{} = img, operator) do
    img |> Image.append_operation(:image_operator, operator)
  end
end
