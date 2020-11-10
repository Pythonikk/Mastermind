# Mastermind

Mastermind is a terminal based take on the classic board game.

## Roadmap

This version provides a slight challenge as the computer can win occasionally. A later version will advance the AI further.  

## Game Rules

The codebreaker gets 12 attempts to break the code.
The code is 4 digits containing numbers 1-6 (i.e 1416).
After each attempt, feedback is given about the guess.
Feedback is given as symbols:
-- ☂  indicates the existence of a correct number but in the wrong position.
-- ☀  indicates a correct number that's in the correct position.
Feedback is not ordered. A guess of 4125 with feedback ☀ ☂  does not mean 4 is given ☀  and 1 is given ☂ .
Scoring: 1 point is given to the codemaker for each guess the codebreaker makes. An additional point is awarded if the codebreaker is unable to guess the code in 12 turns.


