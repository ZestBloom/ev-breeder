'reach 0.1';
'use strict'
// -----------------------------------------------
// Name: Template
// Description: Reach App using Constructor
// Author: Nicholas Shellabarger
// Version: 0.1.0 - update version
// Requires Reach v0.1.9-rc.2 (402c3faa)
// ----------------------------------------------
import { useConstructor } from '@nash-protocol/starter-kit#helium-v0.1.10r1:util.rsh'
import { Participants as AppParticipants,Views, Api, App, Event } from 'interface.rsh'
export const main = Reach.App(() => 
  App(useConstructor(AppParticipants, Views, Api, Event)));
// ----------------------------------------------
