"reach 0.1";
"use strict";

import { requireTok5AmountWithView, depositTokDistinct5 } from "./util.rsh";
// -----------------------------------------------
// Name: Interface Template
// Description: NP Rapp simple
// Author: Nicholas Shellabarger
// Version: 0.0.2 - initial
// Requires Reach v0.1.7 (stable)
// ----------------------------------------------
const BREED_TOKENS = 5;
export const Participants = () => [
  Participant("Manager", {
    getParams: Fun(
      [],
      Object({
        tokens: Array(Token, 1),
      })
    ),
  }),
  Participant("Breeder", {
    getParams: Fun(
      [],
      Object({
        tokens: Array(Token, BREED_TOKENS),
        amount: UInt
      })
    ),
    signal: Fun([], Null)
  }),
  Participant("Claimer", {
    claim: Fun([], Bool)
  }),
  Participant("Relay", {})
];
export const Views = () => [
  View({
    tok0: Token, // ex goETH
    tok1: Token, // ex goETH
    tok2: Token, // ex goETH
    tok3: Token, // ex goETH
    tok4: Token, // ex goETH
    tok5: Token, // ex goETH
    amount: UInt, // ex goETH
    ready: Bool,
    claimed: Bool
  }),
];
export const Api = () => [];
export const App = (map) => {
  const [_, [Manager, Breeder, Claimer, Relay], [v], _] = map;
  const {
    tokens: [tok0, tok1, tok2, tok3, tok4],
  } = requireTok5AmountWithView(Breeder, Claimer, v);
  const {
    tokens: [tok5],
  } = depositTokDistinct5(Manager, Breeder, tok0, tok1, tok2, tok3, tok4, v);
  Claimer.only(() => {
    const doClaim = declassify(interact.claim());
    assume(doClaim == true);
  });
  Claimer.publish(doClaim).timeout(relativeTime(100), () => {
    Anybody.publish();
    transfer(balance(tok5), tok5).to(Manager);
    transfer(balance()).to(Breeder);
    commit();
    exit();
  });
  require(doClaim == true);
  transfer(balance(tok5), tok5).to(Breeder);
  transfer(balance()).to(Manager);
  v.claimed.set(true);
  commit();
  Relay.publish();
  commit();
  exit();
};
// ----------------------------------------------
