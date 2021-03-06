module Main where


import Control.Monad (forever)
import Data.Char (toLower)
import Data.Maybe (isJust)
import Data.List (intersperse)
import System.Exit (exitSuccess)
import System.Random (randomRIO)

type WordList = [String]

allWords :: IO WordList
allWords = do
  dict <- readFile "data/dict.txt"
  return (lines dict)

minWordLength :: Int
minWordLength = 5

maxWordLength :: Int
maxWordLength = 9

gameWords :: IO WordList
gameWords = do
  aw <- allWords
  return (filter gameLength aw) where
    gameLength w =
      let l = length (w :: String)
      in
        l >= minWordLength
        && l < maxWordLength

randomWord :: WordList -> IO String
randomWord wl = do
  randomIndex <- randomRIO (0, length wl - 1)
  return $ wl !! randomIndex

randomWord' :: IO String
randomWord' = gameWords >>= randomWord

data Puzzle =
  Puzzle String [Maybe Char] [Char]

instance Show Puzzle where
  show (Puzzle _ discovered guessed) =
    (intersperse ' ' $
      fmap renderPuzzleChar discovered)
      ++ " Guessed so far: " ++ guessed

freshPuzzle :: String -> Puzzle
freshPuzzle w = Puzzle w (fmap (const Nothing) w) [] 

charInWord :: Puzzle -> Char -> Bool
charInWord (Puzzle s _ _) c = elem c s

alreadyGuessed :: Puzzle -> Char -> Bool
alreadyGuessed (Puzzle _ _ g) c = elem c g

renderPuzzleChar :: Maybe Char -> Char
renderPuzzleChar Nothing = '_'
renderPuzzleChar (Just c) = c

fillInCharacter :: Puzzle -> Char -> Puzzle
fillInCharacter (Puzzle word filledInSoFar s) c =
  Puzzle word newFilledInSoFar (c : s)
  where
    zipper guessed wordChar guessChar =
      if wordChar == guessed
      then Just wordChar
      else guessChar
    newFilledInSoFar =
      zipWith (zipper c)
        word filledInSoFar

handleGuess :: Puzzle -> Char -> IO (Puzzle, Bool)
handleGuess puzzle guess = do
  putStrLn $ "Your guess was: " ++ [guess]
  case (charInWord puzzle guess, alreadyGuessed puzzle guess) of
    (_, True) -> do
      putStrLn "You already guessed that character, pick something else!"
      return (puzzle, True)
    (True, _) -> do
      putStrLn "This character was in the word, filling in the word accordingly"
      return ((fillInCharacter puzzle guess), False)
    (False, _) -> do
      putStrLn "This character wasn't in the word, try again."
      return ((fillInCharacter puzzle guess), True)

gameOver :: Puzzle -> Int -> IO ()
gameOver (Puzzle wordToGuess _ _) mistakes =
  if mistakes > 7 then
    do
      putStrLn "You lose!"
      putStrLn $ "The word was: " ++ wordToGuess
      exitSuccess
  else return ()

gameWin :: Puzzle -> IO ()
gameWin (Puzzle _ filledInSoFar _) =
  if all isJust filledInSoFar then
    do
      putStrLn "You win!"
      exitSuccess
  else return ()

runGame :: Puzzle -> Int -> IO ()
runGame puzzle mistakes = forever $ do
  gameOver puzzle mistakes
  gameWin puzzle
  putStrLn $ "Current puzzle is: " ++ show puzzle
  putStr "Guess a letter: "
  guess <- getLine
  case guess of
    [c] -> do
      (p, wasWrong) <- handleGuess puzzle c
      if wasWrong
      then runGame p (mistakes + 1)
      else runGame p mistakes
    _ ->  putStrLn "Your guess must be a single character"

main :: IO ()
main = do
  word <- randomWord'
  let puzzle = freshPuzzle (fmap toLower word)
  runGame puzzle 0

palindrome :: IO ()
palindrome = forever $ do
  l <- getLine
  case (pal l) of
    True -> putStrLn "It's a palindrome!"
    False -> do
      putStrLn "Nope!"
      exitSuccess

pal :: String -> Bool
pal s =
  normalize s == (reverse . normalize $ s)

normalize :: String -> String
normalize s =
  let lower = fmap toLower s
      nospaces = concat . words
      onlychars = filter (flip elem ['a'..'z'])
  in (nospaces . onlychars) lower
  
