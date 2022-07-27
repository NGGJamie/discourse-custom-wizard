import { visit, settled } from "@ember/test-helpers";
import { test } from "qunit";
import {
  acceptance,
  count,
  query,
  exists,
} from "discourse/tests/helpers/qunit-helpers";
import {
  wizard,
  wizardCompleted,
  wizardNoUser,
  wizardNotPermitted,
} from "../helpers/wizard";

acceptance("Wizard | Not logged in", function (needs) {
  needs.pretender((server, helper) => {
    server.get("/w/wizard.json", (request) => helper.response(wizardNoUser));
  });

  test("Wizard no access requires login", async function (assert) {
    await visit("/w/wizard");
    assert.ok(exists(".wizard-no-access.requires-login"));
  });
});

acceptance("Wizard | Not permitted", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/w/wizard.json", (request) =>
      helper.response(wizardNotPermitted)
    );
  });

  test("Wizard no access not permitted", async function (assert) {
    await visit("/w/wizard");
    assert.ok(exists(".wizard-no-access.not-permitted"));
  });
});

acceptance("Wizard | Completed", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/w/wizard.json", (request) => helper.response(wizardCompleted));
  });

  test("Wizard no access completed", async function (assert) {
    await visit("/w/wizard");
    assert.ok(exists(".wizard-no-access.completed"));
  });
});

acceptance("Wizard | Wizard", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/w/wizard.json", (request) => {
      return helper.response(wizard);
    });
  });

  test("Starts", async function (assert) {
    await visit("/w/wizard");
    assert.ok(query(".wizard-column"), true);
  });

  test("Applies the body background color", async function (assert) {
    await visit("/w/wizard");
    assert.ok($("body")[0].style.background);
  });

  test("Renders the wizard form", async function (assert) {
    await visit("/w/wizard");
    assert.ok(exists(".wizard-column-contents .wizard-step"), true);
    assert.ok(exists(".wizard-footer img"), true);
  });

  test("Renders the first step", async function (assert) {
    await visit("/w/wizard");
    assert.strictEqual(
      query(".wizard-step-title p").textContent.trim(),
      "Text"
    );
    assert.strictEqual(
      query(".wizard-step-description p").textContent.trim(),
      "Text inputs!"
    );
    assert.strictEqual(
      query(".wizard-step-description p").textContent.trim(),
      "Text inputs!"
    );
    assert.strictEqual(count(".wizard-step-form .wizard-field"), 6);
    assert.ok(exists(".wizard-step-footer .wizard-progress"), true);
    assert.ok(exists(".wizard-step-footer .wizard-buttons"), true);
  });
});
