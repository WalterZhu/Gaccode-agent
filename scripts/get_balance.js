#!/usr/bin/env node

const [,, email, password] = process.argv;

if (!email || !password) {
  console.error('Usage: get_balance.js <email> <password>');
  process.exit(1);
}

async function main() {
  const loginRes = await fetch('https://gaccode.com/api/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });

  if (!loginRes.ok) {
    console.error(`Login failed: ${loginRes.status} ${loginRes.statusText}`);
    process.exit(2);
  }

  const loginJson = await loginRes.json();
  const token = loginJson.token;

  if (!token) {
    console.error('Login succeeded but no token returned');
    process.exit(3);
  }

  const balanceRes = await fetch('https://gaccode.com/api/credits/balance', {
    headers: { Authorization: `Bearer ${token}` }
  });

  if (!balanceRes.ok) {
    console.error(`Balance request failed: ${balanceRes.status} ${balanceRes.statusText}`);
    process.exit(4);
  }

  const balanceJson = await balanceRes.json();
  console.log(JSON.stringify(balanceJson, null, 2));
}

main().catch(err => {
  console.error(err);
  process.exit(10);
});
