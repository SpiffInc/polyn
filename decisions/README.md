# Architecture Decision Record (ADR) System

## What is an architecture decision record?

An **architecture decision record** (ADR) is a document that captures an important architectural decision along with its context and consequences.

An **architecture decision** (AD) is a software design choice that addresses a significant requirement.

## ADR file name conventions

Each ADR goes in the `decisions/` directory in the following format: `NNNN-title-with-dashes.md`

Our file name convention:

  * NNNN is a consecutive number and we assume that there won’t be more than 9,999 ADRs in one repository.

  * The name has a present tense imperative verb phrase. This helps readability and matches our commit message format.

  * The name uses lowercase and dashes (same as this repo). This is a balance of readability and system usability.

  * The extension is markdown. This can be useful for easy formatting.

Examples:

  * 0001-choose-database.md

  * 0002-format-timestamps.md

  * 1001-manage-passwords.md

  * 9999-handle-exceptions.md

## Suggestions for writing good ADRs

Use the provided [template](template.md)

Characteristics of a good ADR:

  * Rational: Explain the reasons for doing the particular AD. This can include the context (see below), pros and cons of various potential choices, feature comparions, cost/benefit discussions, and more.

  * Specific: Each ADR should be about one AD, not multiple ADs.

  * Timestamps: Identify when each item in the ADR is written. This is especially important for aspects that may change over time, such as costs, schedules, scaling, and the like.

  * Immutable: Don't alter existing information in an ADR. Instead, amend the ADR by adding new information, or supersede the ADR by creating a new ADR.

Characteristics of a good "Context" section in an ADR:

  * Explain your organization's situation and business priorities.

  * Include rationale and considerations based on social and skills makeups of your teams.

  * Include pros and cons that are relevant, and describe them in terms that align with your needs and goals.

Characteristics of good "Consequences" section in an ADR:

  * Explain what follows from making the decision. This can include the effects, outcomes, outputs, follow ups, and more.

  * Include information about any subsequent ADRs. It's relatively common for one ADR to trigger the need for more ADRs, such as when one ADR makes a big overarching choice, which in turn creates needs for more smaller decisions.

  * Include any after-action review processes. It's typical for teams to review each ADR one month later, to compare the ADR information with what's happened in actual practice, in order to learn and grow.

A new ADR may take the place of a previous ADR:

  * When an AD is made that replaces or invalidates a previous ADR, then a new ADR should be created

## Use of Meetings

Making an Architecture Decision in a meeting is ok to do, but it should be the exception not the rule. There will be times when a high bandwidth, face-to-face conversation is necessary to help move a decision forward. Most of the time we can make decisions without a meeting. Our company is becoming increasingly distributed (different timezones, schedules, caregiving responsibilities etc). Conflicting schedules can prevent people who couldn’t attend a meeting, who otherwise would have made valueable contributions, from understanding or contributing to the decision. A Pull Request style workflow should be used as the default because it acts as a staging place for the decision. This allows the decision to sit for a few days while people think on it and make suggestions when it fits with their schedule. It also keeps a record of the conversation so future travelers can remember how an idea was arrived at. It also helps those who are less-inclined to speak up in meetings or just like contemplating longer, contribute to the discussion. We don't want to lose valuable ideas from team members because of scheduling conflicts, personality differences, or group meeting dynamics.


