"reach 0.1";
"use strict";

import { requireTok2AmountWithView, depositTokDistinct2 } from "./util.rsh";
// -----------------------------------------------
// Name: Interface Template
// Description: NP Rapp simple
// Author: Nicholas Shellabarger
// Version: 0.0.2 - initial
// Requires Reach v0.1.7 (stable)
// ----------------------------------------------
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
        tokens: Array(Token, 2),
        amount: UInt
      })
    ),
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
    amount: UInt, // ex goETH
  }),
];
export const Api = () => [];
export const App = (map) => {
  const [[Manager, Breeder, Claimer, Relay], [v], _] = map;
  const {
    tokens: [tok0, tok1],
  } = requireTok2AmountWithView(Breeder, Claimer, v);
  const {
    tokens: [tok2],
  } = depositTokDistinct2(Manager, Breeder, tok0, tok1);
  Claimer.only(() => {
    const doClaim = declassify(interact.claim());
    assume(doClaim == true);
  });
  Claimer.publish(doClaim).timeout(relativeTime(100), () => {
    Anybody.publish();
    transfer(balance(tok2), tok2).to(Manager);
    transfer(balance()).to(Breeder);
    commit();
    exit();
  });
  require(doClaim == true);
  transfer(balance(tok2), tok2).to(Breeder);
  transfer(balance()).to(Manager);
  commit();
  Relay.publish();
  commit();
  exit();
};
// ----------------------------------------------
