import hmac
import hashlib
import secrets
from typing import List, Union
from app.core.config import settings

# 256 Unique Cyberpunk Samurai Wordlist for Neuromodem Seed Phrases
CYBER_WORDLIST: List[str] = [
    "ronin", "katana", "samurai", "bushido", "wakizashi", "shuriken", "shogun", "shinobi",
    "kaze", "torii", "dojo", "tsunami", "sakura", "zenith", "shadow", "blade",
    "cyber", "matrix", "neon", "glitch", "chrome", "neural", "pulse", "stealth",
    "cyborg", "terminal", "ghost", "shell", "avatar", "datapad", "optic", "reflex",
    "nexus", "netrunner", "cipher", "overclock", "daemon", "vector", "subnet", "laser",
    "plasma", "torque", "sector", "proxy", "node", "firewall", "crypto", "signal",
    "scanner", "bypass", "protocol", "quantum", "mainframe", "uplink", "downlink", "socket",
    "buffer", "packet", "circuit", "silicon", "nano", "implant", "dorsal", "cortex",
    "synapse", "axon", "retina", "visor", "holonet", "fiber", "router", "gateway",
    "payload", "exploit", "trojan", "worm", "sandbox", "kernel", "bytecode", "compiler",
    "thread", "mutex", "daemon", "vault", "ledger", "token", "hash", "entropy",
    "rebel", "syndicate", "corp", "zaibatsu", "underground", "slums", "arcology", "sprawl",
    "megacity", "orbit", "beacon", "satellite", "relay", "frequency", "sonar", "radar",
    "stealth", "covert", "assassin", "mercenary", "bounty", "contract", "target", "strike",
    "parry", "stance", "strike", "honor", "creed", "vow", "oath", "blade",
    "armor", "chitin", "kevlar", "graphene", "alloy", "titanium", "carbon", "plasma",
    "fusion", "reactor", "battery", "dynamo", "generator", "turbine", "overdrive", "boost",
    "velocity", "warp", "drift", "grid", "wire", "patch", "glitch", "static",
    "noise", "echo", "whisper", "phantom", "specter", "wraith", "banshee", "shade",
    "void", "abyss", "eclipse", "aurora", "dusk", "dawn", "midnight", "twilight",
    "frost", "blaze", "spark", "volt", "ampere", "joule", "watt", "current",
    "flux", "surge", "shock", "discharge", "battery", "ion", "laser", "beam",
    "focus", "prism", "mirror", "lens", "shutter", "aperture", "sensor", "scanner",
    "tracker", "tracer", "vector", "trajectory", "crosshair", "scope", "zenith", "apex",
    "nadir", "stratum", "sublevel", "sector", "district", "zone", "corridor", "trench",
    "skyline", "monolith", "tower", "spire", "citadel", "bastion", "stronghold", "haven",
    "sanctuary", "bunker", "shelter", "vault", "archive", "library", "codex", "scroll",
    "record", "manifest", "registry", "index", "catalog", "directory", "nexus", "core",
    "crucible", "forge", "anvil", "hammer", "crucible", "furnace", "hearth", "spark",
    "cinder", "ember", "ash", "dust", "smoke", "haze", "fog", "vapor",
    "steam", "fluid", "coolant", "hydraulics", "pneumatic", "servo", "actuator", "gear",
    "sprocket", "cog", "cam", "crank", "bearing", "piston", "valve", "manifold"
]

# Ensure uniqueness while preserving order
CYBER_WORDLIST = list(dict.fromkeys(CYBER_WORDLIST))


def generate_seed_phrase(word_count: int = 12) -> List[str]:
    """Generate a random 12-word cyberpunk seed phrase."""
    return [secrets.choice(CYBER_WORDLIST) for _ in range(word_count)]


def normalize_seed_phrase(phrase: Union[str, List[str]]) -> str:
    """Normalize seed phrase into lowercase space-delimited words."""
    if isinstance(phrase, list):
        words = phrase
    else:
        words = phrase.strip().split()
    return " ".join([w.strip().lower() for w in words if w.strip()])


def hash_seed_phrase(phrase: Union[str, List[str]]) -> str:
    """Compute HMAC-SHA256 hash for deterministic seed phrase lookup."""
    normalized = normalize_seed_phrase(phrase)
    key = settings.SECRET_KEY.encode("utf-8")
    return hmac.new(key, normalized.encode("utf-8"), hashlib.sha256).hexdigest()


def verify_seed_phrase(phrase: Union[str, List[str]], hashed: str) -> bool:
    """Verify seed phrase matches the stored hash."""
    computed = hash_seed_phrase(phrase)
    return hmac.compare_digest(computed, hashed)
