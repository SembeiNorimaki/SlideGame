class_name AnswerMatcher
extends RefCounted
## Compares a typed answer with a list of accepted answers.
## Ignores case, accents (á -> a, ü -> u; ñ stays ñ), spaces and
## punctuation, so "Water-drop", "waterdrop" and "WATER DROP" all match
## "water drop", and "corazon" matches "corazón".

const _FOLD := {
	"á": "a", "à": "a", "â": "a", "ä": "a", "ã": "a", "å": "a",
	"é": "e", "è": "e", "ê": "e", "ë": "e",
	"í": "i", "ì": "i", "î": "i", "ï": "i",
	"ó": "o", "ò": "o", "ô": "o", "ö": "o", "õ": "o",
	"ú": "u", "ù": "u", "û": "u", "ü": "u",
	"ç": "c", "ý": "y", "ÿ": "y",
}


## Lowercase, accent-free, letters and digits only.
static func normalize(text: String) -> String:
	var out := ""
	for ch in text.to_lower():
		ch = _FOLD.get(ch, ch)
		if _is_letter_or_digit(ch):
			out += ch
	return out


static func matches(guess: String, accepted: PackedStringArray) -> bool:
	var g := normalize(guess)
	if g.is_empty():
		return false
	for answer in accepted:
		if normalize(answer) == g:
			return true
	return false


static func _is_letter_or_digit(ch: String) -> bool:
	var c := ch.unicode_at(0)
	return (c >= 48 and c <= 57) or ch.to_lower() != ch.to_upper()
