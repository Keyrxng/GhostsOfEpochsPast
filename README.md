# Ghosts Of Epochs Past (beta)



## Demographic

The demographic of this dApp is primarily being aimed at newbies in blockchain/EVM related security research, looking to improve and refresh their knowledge.

## Problem This Solves

Accessing the Secureum and other security related materials that aren't yet in this build is all free of charge in the discord server, however, the answers are exposed and the burden of proof is on the students to ensure that they are engaged, completing the challenge and obtaining the prize of knowledge. This provides little mental stimuli and incentive to hide the answers (even still, you've seen them now) and test yourself. This is where we come in, with *Ghosts Of Epochs Past*, a dApp which attempts to provide more incentice to learn from previous epochs as opposed to *scannning the answers* for a test you haven't done yet.

## How We Solve It?

[GhostsOfEpochsPast](https://ghostsofepochspast.com/) is a place to study and revise previous race epochs provided by [Secureum](https://secureum.xyz/), a community of like minded crypto enthusiasts with a focus on **Ethereum**, **Solidity** and **Smart Contract Security**. There is no time limit unlike the real races (which you, fellow security researcher should be aiming to apply to participate in once you complete these stress free revisions). Your answers are hashed and verified on-chain, yes we are aware there are ways to cheat but that defeats the purpose. You should be old enough and resourceful enough to effectively learn from this material and not need to rely on shortcuts to "win", as you'll never place in C4 with that attitude.

## How To Get Started?

* Create a user profile consisting of your alias, job title, bio and a social handle of choice.
* Go to the first race (technically it's race 4 as secureum released their content from this epoch forward) but we know it as race 1.
* Mint your WarmUp NFT. This allows you access to attempt to complete the race with the correct answers.
* Pick your answers and then **Off-chain Submit** them which will generate your results but they will be hidden until revealed.
* If you are brave you can **On-chain Submit** at this point, it will only ask you to sign a transaction if you got them all correct.
* If you are not feeling so brave, you can review your results and correct your mistakes before submitting correctly.
* Your WarmUp NFT has just been upgraded to a RaceNFT which signifies you have completed that specific race.
* You are now eligible to attempt the next race. Proceed to the next race and mint your WarmUpNFT to begin.

## Why It's Unique?

It's unique in that it is a *FREE* learning platform purely built to help newbies access the incredible free content provided by Secureum, at their own pace and to familiarize themselves with Solidity and Smart Contract Security as a whole. There are other platforms like this, but currently none of them are as friendly to newbies. We're not looking to provide a paid service as we're pretty sure Secureum would frown upon that, instead we'd like to open this up to the community to gain as much value as possible and provide a pipeline to the Secureum Discord (and others) for those that really want to hit the ground running on their crypto security career.

## What's Next?

### Some key features we plan to add if we receive good feedback from the community:

* The addition of all public Secureum race epochs, not just the four for the beta.
* The addition of other 3rd party quiz and learning content from niche specific DAO's and creators.
* Increase the *'socialness'* of the UX and UI by introducing a social graph, user follows and user feed (i.e seeing other user profiles, recent completed races/challenges by those a user follows in the form of a feed) and maybe even some ranking system.
* The addition of a blockchain security research focused blog/content section.
* A more comprehensive list of security tips (as seen on the dashboard)
* A calendar to track industry wide time restricted security events such as new Epoch registration times, QuillCTF competition timings, etc.
* Open to other suggestions and feedback as well.

## Tech Stack

* Solidity (Smart contracts)
* Foundry (Solidity Testing Framework)
* React.js / Next.js
* RainbowKit
* Wagmi

## Accreditations

**Secureum** for providing such great content that is easily accessible and challenging enough to learn a lot from.

## Contributors

[**Rixican**](https://github.com/rixcian)! NFT Artwork creator and designer.

[**Phoenix**](https://github.com/johnnyknoxville1337)! DevRel (Videos, Documents, etc).

[**MartinSuperfast**](https://linktr.ee/studiosuperfast)! Artwork and illustrations for *yet* unrealeased content.

[**Keyrxng**](https://github.com/Keyrxng)! Full Frontend & Backend development.

* * *
<br/>

## Known Issues / Bugs:

* Edge cases occur in the sorting of submitted answers. As on-chain verification is done using keccak256 hashing, answers must be submitted in ascending order. To fix, unselect then reselect in ascending order.

* Edge cases occur in the performance calculation where it may be inaccurate, to fix unselect and then reselect the problem answer(s), off-chain submit should now be accurate to submit on-chain.

* Please report any issues that you find either via the issues tab on this repo or through any other means.


## TODOS:

* Add section to the right of 'About' in profile page, a trophy case for completed race NFTs.

## Active Pages:

* **home** www.url.com || /pages/index.js

* **dashboard** www.url.com/dashboard || /pages/dashboard/index.js

* **Profile** www.url.com/dashboard/profile || /pages/dashboard/profile.js

* **[raceId]** www.url.com/dashboard/races/[raceId] || /pages/dashboard/races/[raceId].js


<br/>

* * *
