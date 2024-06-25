defmodule PortsTest do
  use ExUnit.Case, async: true
  doctest Ports

  describe "ports" do
    test "all/0 get all ports" do
      ports = Ports.all()
      assert Enum.count(ports) == 116_074
    end

    test "all/0 returns ports with country and location" do
      assert Enum.all?(Ports.all(), fn port ->
               port.country not in ["", nil] and port.location not in ["", nil]
             end)
    end

    test "all/0 returns ports having name with proper characters" do
      assert Enum.all?(Ports.all(), fn port ->
               !String.contains?(port.name, "�")
             end)
    end

    test "all/0 returns ports having name with valid string" do
      assert Enum.all?(Ports.all(), fn port ->
               String.valid?(port.name)
             end)
    end
  end

  describe "countries" do
    test "countries/0 get all countries" do
      countries = Ports.countries()
      assert Enum.count(countries) == 249
    end

    test "get_country/1 gets one country" do
      %{code: code, name: name} = Ports.get_country("PH")
      assert code == "PH"
      assert name == "Philippines"
    end
  end

  describe "functions" do
    test "functions/0 get all functions" do
      functions = Ports.functions()
      assert Enum.count(functions) == 10
    end

    test "get_function/1 gets one function" do
      %{code: code, description: description} = Ports.get_function(4)
      assert code == "4"
      assert description == "Airport"
    end
  end

  describe "statuses" do
    test "statuses/0 get all statuses" do
      statuses = Ports.statuses()
      assert Enum.count(statuses) == 14
    end

    test "get_status/1 gets one status" do
      %{code: code, description: description} = Ports.get_status("AA")
      assert code == "AA"
      assert description == "Approved by competent national government agency"
    end
  end

  describe "subdivisions" do
    test "subdivisions/0 get all subdivisions" do
      subdivisions = Ports.subdivisions()
      assert Enum.count(subdivisions) == 4743
    end

    test "get_subdivision/2 gets one subdivision" do
      %{country: country, code: code, name: name} = Ports.get_subdivision("PH", "00")
      assert country == "PH"
      assert code == "00"
      assert name == "National Capital Region (Manila)"
    end
  end
end
