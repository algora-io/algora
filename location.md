# Scenarios

## Onsite SF/NY, relocation supported within US

```elixir
states: ["US-CA", "US-NY"]
location_types: [:onsite]
countries: ["US"]
```

## Hybrid SF, relocation supported globally

```elixir
states: ["US-CA"]
location_types: [:hybrid]
countries: []
```

## Hybrid London/Berlin, relocation supported within the EU

```elixir
states: ["GB-ENG", "DE-BE"]
location_types: [:hybrid]
countries: ["EU"]
```

## Remote US

```elixir
states: []
location_types: [:remote]
countries: ["US"]
```

## Remote global

```elixir
states: []
location_types: [:remote]
countries: []
```

# Rules:

1. Never match hybrid/onsite role with remote only user
   e.g. user with `u.open_to_remote && !open_to_hybrid && !open_to_onsite` does not match SF onsite role
2. If u.location_iso_lvl4 is null, allow it to match any state within user's country
   e.g. user with country `"US"` and state `null` matches role with state `"US-CA"`
3. If all user relocation fields are false (user did not provide prefs), allow it to match any relocation allowed
   e.g. user with country `"US"` and state `"US-MA"` and false relo fields matches onsite SF role
4. If any relo field is true, match accordingly
   e.g. user with country `"US"` and state `"US-WA"` and open_to_relocate_sf `true` matches role with states `["US-CA"]` and countries `["US"]`
   e.g. user with country `"DE"` and open_to_relocate_sf `true` matches role with states `["US-CA"]` and countries `[]`
   e.g. user with country `"DE"` and open_to_relocate_sf `true` DOES NOT MATCH role with states `["US-CA"]` and countries `["US"]`
   e.g. user with country `"DE"` and open_to_relocate_world `true` matches role with states `["US-CA"]` and countries `[]`
   e.g. user with country `"US"` and open_to_relocate_country `true` matches role with states `["US-CA"]` and countries `["US"]`
