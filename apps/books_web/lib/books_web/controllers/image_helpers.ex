defmodule BooksWeb.ImageHelpers do
  @moduledoc """
  Image helpers for getting pub image files, and information from PNG files.
  """

  @default_pub_path "pub"

  defp pub_path do
    Application.get_env(:books_web, :pub_path, @default_pub_path)
  end

  def get_post_image(name) do
    Path.join([pub_path(), "posts", name])
  end

  def get_background_image(name) do
    Path.join([pub_path(), "backgrounds", name])
  end

  def get_post_images do
    Path.wildcard(get_post_image("*.png"))
  end

  def get_background_images do
    Path.wildcard(get_background_image("*.{png,jpg}"))
  end

  def info(file) do
    file
    |> Path.extname()
    |> String.trim_leading(".")
    |> MIME.type()
    |> case do
      "image/png" -> png_info(file)
      type -> {:error, "Unknown #{type}"}
    end
  end

  def png_info(file) do
    case File.read(file) do
      {:ok, data} -> png_header_info(data)
      {:error, _reason} = error -> error
    end
  end

  defp png_header_info(
         <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _length::size(32), "IHDR",
           width::size(32), height::size(32), bit_depth, color_type, compression_method,
           filter_method, interlace_method, _crc::size(32), _chunks::binary>>
       ) do
    %{
      width: width,
      height: height,
      bit_depth: bit_depth,
      color_type: color_type,
      compression: compression_method,
      filter: filter_method,
      interlace: interlace_method
    }
  end
end
