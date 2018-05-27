defmodule Rps do
  @moduledoc """
  The `RPS` app is composed by 4 main components:

    * `Rps.Games.Fsm` - This might be the main component, since it is the one
      that implements the logic of the game itself; it handles the game session.
      When a match is created, a new FSM (or session) instance can be created
      and then the game starts. The FSM handles the whole logic, controlls every
      round and updated all needed information in the database. When the game
      finishes, the FSM updated the match with the final result and the winner
      user to increments the score. The FSM instances are supervised by
      `Rps.Games.Fsm.Supervisor`, which implements a `:simple_one_for_one`
      strategy, so the FSM instances are added and deleted dynamically
      (on-demand) Check the `Rps.Games.Fsm` module for more info.

    * `Rps.Games.Leaderboard` - This module holds the leaderboard or ranking
      about the game. It is implemented as a `GenServer` in order to provide an
      owner for the ETS tables (according to the ETS ownership best practices),
      but the access itself is done directly against the tables. The leaderboard
      itself is implemented using two ETS tables. For more information about
      its implementation check the `Rps.Games.Leaderboard` module doc.

    * REST API - The functionality of the game will be exposed via HTTP, using
      a REST API. There are several controllers, but the relevant ones are:

      * `RpsWeb.SessionController` to requests access tokens (authentication).
      * `RpsWeb.MatchController` to create games and also join to existing
        games.
      * `RpsWeb.RoundController` to play, this controller allows players to
        send their moves but associated to a particular game.
      * `RpsWeb.LeaderboardController` to show the leaderboard or ranking.

    * Notifications - The notifications are implemented using Phoenix Channels,
      which uses WebSocket internally. The channel `RpsWeb.RoomChannel` allows
      users to subscribe to a particular topic, and the topic in this case is
      the `id` of the game (or match). Once the players are subscribed to the
      game (topic), they will receive notifications about the result of each
      round (`Rps.Games.Round`) and once the game finished they will receive
      also the info about the game (`Rps.Games.Match`). The module in charge
      to send these notifications is the `Rps.Games.Fsm`, since it is the one
      that controlls the logic of the game (check this module, the private
      function `push` and the places where it is being invoked).

  ## Game Options

  The following options can be defined in your config file:

    * `:match_rounds` - max number of rounds per match. Default is `10`.

    * `:round_timeout` - timeout per round. Default is `10000`.
  """
end
