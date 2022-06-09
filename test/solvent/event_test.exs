defmodule Solvent.EventTest do
  use ExUnit.Case, async: true
  doctest Solvent.Event
  alias Solvent.Event

  describe "to_json/1" do
    test "encodes string fields as string" do
      decoded_json =
        %Event{
          id: "string-id",
          type: "com.example.event.published",
          source: "Solvent",
          specversion: "1.0"
        }
        |> Event.to_json!()
        |> Jason.decode!()

      assert Enum.sort(Map.keys(decoded_json)) == ["datacontenttype", "id", "source", "specversion", "type"]
      assert decoded_json["datacontenttype"] == "application/json"
      assert decoded_json["id"] == "string-id"
      assert decoded_json["source"] == "Solvent"
      assert decoded_json["specversion"] == "1.0"
      assert decoded_json["type"] == "com.example.event.published"
    end

    test "encodes extension fields" do
      decoded_json =
        %Event{
          id: "string-id",
          type: "com.example.event.published",
          source: "Solvent",
          specversion: "1.0",
          extensions: %{
            "comexamplecorrelationid" => "correlation-id"
          }
        }
        |> Event.to_json!()
        |> Jason.decode!()

      assert decoded_json["comexamplecorrelationid"] == "correlation-id"
    end

    test "encodes binary data into base-64" do
      decoded_json =
        %Event{
          id: "string-id",
          type: "com.example.event.published",
          source: "Solvent",
          specversion: "1.0",
          datacontenttype: "application/octet-stream",
          data: <<1, 2, 3>>
        }
        |> Event.to_json!()
        |> Jason.decode!()

      assert decoded_json["data_base64"] == "AQID"
    end
  end

  describe "from_json" do
    test "decodes a basic struct" do
      {:ok, result} =
        "{\"datacontenttype\":\"application/json\",\"id\":\"string-id\",\"source\":\"Solvent\",\"specversion\":\"1.0\",\"type\":\"com.example.event.published\"}"
        |> Event.from_json()

      assert result.id == "string-id"
      assert result.specversion == "1.0"
      assert result.source == "Solvent"
      assert result.type == "com.example.event.published"
    end

    test "decodes extensions" do
      {:ok, result} =
        File.read!("test/json/xml.json")
        |> Event.from_json()

      assert result.extensions["comexampleextension1"] == "value"
    end

    test "decodes the time field" do
      {:ok, result} =
        File.read!("test/json/xml.json")
        |> Event.from_json()

      assert result.time == ~U[2018-04-05T17:31:00Z]
    end
  end
end
