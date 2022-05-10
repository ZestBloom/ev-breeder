import { loadStdlib } from "@reach-sh/stdlib";
import * as oracleBackend from "./build/oracle.index.main.mjs";
import * as remoteBackend from "./build/index.main.mjs";
import assert from "assert";

const [, , infile] = process.argv;

(async () => {
  console.log("START");

  const stdlib = await loadStdlib();
  const startingBalance = stdlib.parseCurrency(1000);

  const accAlice = await stdlib.newTestAccount(startingBalance);
  const accBob = await stdlib.newTestAccount(startingBalance);
  const accEve = await stdlib.newTestAccount(startingBalance);

  const accs = await Promise.all(
    Array.from({ length: 10 }).map(() => stdlib.newTestAccount(startingBalance))
  );

  const reset = async (accs) => {
    console.log("Resetting ...");
    await Promise.all(accs.map(rebalance));
    await Promise.all(
      accs.map(async (el) =>
        console.log(`balance (acc): ${await getBalance(accAlice)}`)
      )
    );
  };

  const rebalance = async (acc) => {
    if ((await getBalance(acc)) > 1000) {
      await stdlib.transfer(
        acc,
        accEve?.networkAccount?.addr,
        stdlib.parseCurrency((await getBalance(acc)) - 1000)
      );
    } else {
      await stdlib.transfer(
        accEve,
        acc?.networkAccount?.addr,
        stdlib.parseCurrency(1000 - (await getBalance(acc)))
      );
    }
  };

  const showBalance = async (acc, acc2) => {
    const balAcc = await getBalance(acc);
    const balAcc2 = await getBalance(acc2);
    console.log({ balAcc, balAcc2 });
  };

  const getParams = (addr) => ({
    addr,
    amt: stdlib.parseCurrency(1),
  });

  const testCanDeletInactive = async (backend, i) => {
    console.log(`CAN DELETED INACTIVE (${i})`);
    (async (acc) => {
      let addr = acc?.networkAccount?.addr;
      let ctc = acc.contract(backend);
      backend
        .Constructor(ctc, {
          getParams: () => getParams(addr),
        })
        .catch(console.dir);
      let appId = stdlib.bigNumberToNumber(await ctc.getInfo());
      console.log({ appId });
      await backend.Verifier(ctc, {});
    })(accAlice);
    await stdlib.wait(10);
  };

  const testCanActivateWithPayment = async (backend, i) => {
    console.log(`CAN ACTIVATE WITH PAYMENT (${i})`);
    await (async (acc, acc2) => {
      let addr = acc?.networkAccount?.addr;
      let ctc = acc.contract(backend);
      Promise.all([
        backend.Constructor(ctc, {
          getParams: () => getParams(addr),
        }),
      ]);
      let appId = await ctc.getInfo();
      let ctc2 = acc2.contract(backend, appId);
      backend.Contractee(ctc2, {});
      await stdlib.wait(50);
    })(accAlice, accBob);
    await stdlib.wait(4);
  };

  // ---------------------------------------------

  console.log("BEGIN");

  const backends = [oracleBackend, remoteBackend];

  const zorkmid = await stdlib.launchToken(accAlice, "zorkmid", "ZMD");
  const gil = await stdlib.launchToken(accBob, "gil", "GIL");
  await accAlice.tokenAccept(gil.id);
  await accBob.tokenAccept(zorkmid.id);

  const getBalance = async (who) =>
    stdlib.formatCurrency(await stdlib.balanceOf(who), 4);

  const beforeAlice = await getBalance(accAlice);
  const beforeBob = await getBalance(accBob);

  console.log({ beforeAlice, beforeBob });

  await showBalance(accAlice, accBob);

  // (1) can be deleted before activation

  await Promise.all(backends.map(testCanDeletInactive));

  await showBalance(accAlice, accBob);

  await reset([accAlice, accBob]);

  await showBalance(accAlice, accBob);

  // (2) constructor receives payment on activation

  await Promise.all(backends.map(testCanActivateWithPayment));

  await showBalance(accAlice, accBob);

  await (async () => {
    const afterAlice = await getBalance(accAlice);
    const afterBob = await getBalance(accBob);
    const diffAlice = Math.round(afterAlice - beforeAlice);
    const diffBob = Math.round(afterBob - beforeBob);
    console.log(
      `Alice went from ${beforeAlice} to ${afterAlice} (${diffAlice}).`
    );
    console.log(`Bob went from ${beforeBob} to ${afterBob} (${diffBob}).`);
    assert.equal(diffAlice, 2);
    assert.equal(diffBob, -2);
  })();

  await reset([accAlice, accBob]);

  await showBalance(accAlice, accBob);

  // ↑ boilerplate

  // (3) create oracle
  let oracleCtcInfo;
  console.log(`CAN CREATE ORACLE`);
  await (async (backend, acc) => {
    let addr = acc?.networkAccount?.addr;
    let ctc = acc.contract(backend);
    Promise.all([
      backend.Constructor(ctc, {
        getParams: () => getParams(addr),
      }),
      backend.Contractee(ctc, {}),
      backend.Manager(ctc, {
        getParams: () => ({
          token: zorkmid.id,
          amount: stdlib.parseCurrency(2),
        }),
      }),
    ]).catch(console.dir);
    oracleCtcInfo = stdlib.bigNumberToNumber(await ctc.getInfo());
    await stdlib.wait(100);
    let amount = stdlib.formatCurrency((await ctc.v.amount())[1]);
    let token = stdlib.bigNumberToNumber((await ctc.v.token())[1]);
    console.log({ amount, token });
  })(oracleBackend, accAlice);
  await stdlib.wait(50);
  console.log({ oracleCtcInfo });

  // (4) can remote oracle
  console.log(`CAN REMOTE INTO ORACLE`);
  await (async (backend, acc) => {
    let addr = acc?.networkAccount?.addr;
    let ctc = acc.contract(backend);
    Promise.all([
      backend.Constructor(ctc, {
        getParams: () => getParams(addr),
      }),
      backend.Contractee(ctc, {}),
      backend.Manager(ctc, {
        getParams: () => ({
          oracle: oracleCtcInfo,
        }),
        log: (msg) => console.log(stdlib.bigNumberToNumber(msg))
      }),
    ]).catch(console.dir);
    const ctcInfo = stdlib.bigNumberToNumber(await ctc.getInfo());
    console.log({ ctcInfo });
  })(remoteBackend, accAlice);
  await stdlib.wait(50);

  console.log("DONE");
  process.exit();
})();
