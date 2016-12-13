defmodule Mogrify.Image do
  alias Mogrify.Image

  @type path        :: binary
  @type ext         :: binary
  @type format      :: binary
  @type width       :: integer
  @type height      :: integer
  @type animated    :: boolean
  @type frame_count :: integer
  @type operations  :: Keyword.t
  @type dirty       :: %{atom => any}

  @type t :: %__MODULE__{
    path:        path,
    ext:         ext,
    format:      format,
    width:       width,
    height:      height,
    animated:    animated,
    frame_count: frame_count,
    operations:  operations,
    dirty:       dirty
  }

  defstruct [
    path:        nil,
    ext:         nil,
    format:      nil,
    width:       nil,
    height:      nil,
    animated:    false,
    frame_count: 1,
    operations:  [],
    dirty:       %{}
  ]

  @frame_match_regex ~r/\b\[[1-9][0-9]*] \S+ \d+x\d+/

  def from_map(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct
    |> Map.drop([:__struct__])
    |> from_map
  end
  def from_map(map = %{}) do
    %Image{
      path:        map |> Map.get(:path),
      ext:         map |> Map.get(:ext),
      format:      map |> Map.get(:format),
      width:       map |> Map.get(:width),
      height:      map |> Map.get(:height),
      animated:    map |> Map.get(:animated),
      frame_count: map |> Map.get(:frame_count),
      operations:  map |> Map.get(:operations),
      dirty:       map |> Map.get(:dirty),
    }
  end

  def put_frame_count(%Image{animated: false} = img, _) do
    %{ img | frame_count: 1 }
  end
  def put_frame_count(%Image{} = img, text) do
    frame_count =
      @frame_match_regex # skip the [0] lines which may be duplicated
      |> Regex.scan(text)
      |> length
      |> Kernel.+(1) # add 1 for the skipped [0] frame
    %{ img | frame_count: frame_count }
  end

  def update_dirty(%Image{dirty: dirty} = img, key, val) do
    %{ img | dirty: Map.put(dirty, key, val) }
  end

  def append_operation(%Image{operations: ops} = img, key, val) do
    %{ img | operations: ops ++ [{key, val}] }
  end

  def after_command(%Image{} = image, output_path) do
    %{ image |
      path: output_path,
      ext: Path.extname(output_path),
      format: Map.get(image.dirty, :format, image.format),
      operations: [],
      dirty: %{},
    }
  end



end
