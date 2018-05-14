import System.Time (getClockTime, ClockTime(..))
import qualified Data.ByteString.Lazy as LZ

import Data.Binary
import OpenSSL.RSA
import Control.Arrow (second)
import Codec.Encryption.RSA.NumberTheory (extEuclGcd)

import qualified Data.OpenPGP as OpenPGP
import qualified Data.OpenPGP.Crypto as OpenPGP

main :: IO ()
main = do
	time <- getClockTime
	let TOD t _ = time

	nkey <- generateRSAKey' 1024 65537

	let secretKey = OpenPGP.SecretKeyPacket {
		OpenPGP.version = 4,
		OpenPGP.timestamp = fromIntegral t,
		OpenPGP.key_algorithm = OpenPGP.RSA,
		OpenPGP.key = map (second OpenPGP.MPI)
			[('n', rsaN nkey), ('e', rsaE nkey),
			('d', rsaD nkey), ('p', rsaP nkey), ('q', rsaQ nkey),
			('u', fst $ extEuclGcd (rsaP nkey) (rsaQ nkey))],
		OpenPGP.s2k_useage = 0,
		OpenPGP.symmetric_algorithm = undefined,
		OpenPGP.s2k = undefined,
		OpenPGP.encrypted_data = undefined,
		OpenPGP.is_subkey = False }

	let userID = OpenPGP.UserIDPacket "Test <test@example.com>"
	let message = OpenPGP.Message[ secretKey, userID ]

	let message' = OpenPGP.Message [ secretKey, userID,
		OpenPGP.sign message message OpenPGP.SHA256 [] (fromIntegral t)]

	LZ.putStr $ encode message'
