# Rock-Paper-Scissors Multiplayer Game

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Learn more


```elixir
Rps.Repo.insert! %Rps.Games.Match{player1_id: 1, player2_id: 2}

match = Rps.Repo.get! Rps.Games.Match, 1

Rps.Games.get_match_with_rounds 10

Rps.Games.Fsm.Supervisor.start_child 11
Rps.Games.Fsm.move 10, 1, "rock"
Rps.Games.Fsm.move 10, 2, "paper"

Rps.Games.Fsm.Supervisor.start_child 1
Rps.Games.Fsm.move 1, 1, "rock"
Rps.Games.Fsm.move 1, 2, "paper"
Rps.Games.Fsm.info 1

Rps.Games.Fsm.get_pid 1
Rps.Games.Fsm.Supervisor.terminate_child 1
Rps.Games.Fsm.get_pid 1
```
