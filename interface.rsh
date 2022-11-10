"reach 0.1";
"use strict";

import { requireAmountWithView, depositTokDistinct2 } from "./util.rsh";
// -----------------------------------------------
// Name: Interface Template
// Description: NP Rapp simple
// Author: Nicholas Shellabarger
// Version: 0.0.2 - initial
// Requires Reach v0.1.7 (stable)
// ----------------------------------------------
export const Event = () => [];
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
        amount: UInt
      })
    ),
    signal: Fun([], Null)
  }),
  Participant("Claimer", {
    claim: Fun([], Bool)
  }),
  ParticipantClass("Relay", {})
];
export const Views = () => [
  View({
    tok0: Token, // ex goETH
    tok1: Token, // ex goETH
    amount: UInt, // ex goETH
    ready: Bool,
    claimed: Bool
  }),
];
export const Api = () => [];
export const App = (map) => {
  const [{ amt, ttl, tok0, tok1 }, [addr, _], [Manager, Breeder, Claimer, Relay], [v], _, _] = map;
  requireAmountWithView(Breeder, Claimer, Relay, v, addr, amt, ttl, tok0, tok1);
  const {
    tokens: [tok2],
  } = depositTokDistinct2(Manager, Breeder, Relay, tok0, tok1, v);
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
  v.claimed.set(true);
  commit();
  Relay.publish();
  commit();
  exit();
};
// ----------------------------------------------
