---
status: accepted
date: 2022-10-26
deciders: Brandyn Bennett
consulted:
informed:
---

# Use ADR System

## Context and Problem Statement

Need a way to remember decisions and understand them.

## Decision Drivers

1. The reason for the decision becomes tribal knowledge that only exists in the memories of certain team members.
2. Team members who weren't involved in the decision have to either blindly accept it or blindly change it.
3. Lack of understanding for why decicions were made increases the fear to change the project leading to ever increasing entropy.
4. Making changes without understanding why decisions were made increases the probability of causing a preventable breakage.
5. Contributing to important decisions is limited to silos of people in the same timezone that can join a synchronous meeting.

## Considered Options

* No ADRs
* Yes ADRs

## Decision Outcome

Use an ADR system. While there may be some initial overhead to write our decisions down in a collaborative way, it outweighs the overhead of not writing it down. In order to collaborate effectively and efficiently we need a system of recording decisions.

### Positive Outcomes

* We'll be able to remember why the system is built in a certain way
* We'll be able to make changes more confidently
* Collaboration will be easier because there will be a shared history
* Project will be more maintainable long term

### Negative Outcomes

* May take more upfront investment
* May forget to record some decisions


## Validation

We will know the system is working if conversations about architecture changes are recorded in the system. New and existing engineers will be able to look at the system and understand the current state and/or the current direction. The documentation will stay up to date organically as it becomes frequently read and written as a core part of the process.

## Pros and Cons of the Options

### No ADRS

* Pro: Decisions are sometimes faster this way
* Pro: Not recording things is less initial overhead
* Pro: We have more excuses to talk face-to-face which is more enjoyable

* Con: Only certain people remember why decisions were made, if they remember at all
* Con: We repeat past mistakes or past conversations because we didn't record it
* Con: The system becomes difficult to change because no one remembers why things are a certain way and are too afraid of breaking it.
* Con: It takes longer to make decisions because we struggle to find time on the schedules of very busy people when their disparate timezones overlap
* Con: Less voices contribute to the decision because the meetings don't fit with their scheduled