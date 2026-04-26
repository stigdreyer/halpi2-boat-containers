# halpi2-boat-containers

Personal HaLOS container store + app definitions for a HALPI2-based boat
computer. Provides Home Assistant, Music Assistant (with Spotify, Spotify
Connect, internet radio, and a local-library provider), and a Snapcast client
that plays audio out the host's HDMI.

This repo is structured to mirror
[halos-org/halos-marine-containers](https://github.com/halos-org/halos-marine-containers)
so the same `container-packaging-tools` pipeline produces installable `.deb`
files.

## What's in here

```
halpi2-boat-containers/
├── store/                     # "boat" store definition (.deb that registers
│                              #   the store in Cockpit Container Apps)
├── apps/
│   ├── homeassistant/         # Home Assistant Core
│   ├── music-assistant/       # Music Assistant Server (incl. bundled Snapserver)
│   └── snapclient/            # Snapcast client; owns /dev/snd → HDMI
├── tools/
│   └── build-all.sh           # Build all .deb packages
└── .github/workflows/         # Build on push, release on tag
```

## Building locally

Requirements on the build host:

- `dpkg-buildpackage`, `debhelper` (`sudo apt install dpkg-dev debhelper`)
- `uv` (for `uvx`): https://docs.astral.sh/uv/

```bash
./tools/build-all.sh
ls build/*.deb
```

Outputs (with default `--prefix boat`):

- `boat-container-store_<version>_all.deb`
- `boat-homeassistant-container_<version>_all.deb`
- `boat-music-assistant-container_<version>_all.deb`
- `boat-snapclient-container_<version>_all.deb`

## Installing on a HALPI2

```bash
# Copy or wget the .deb files to the HALPI2, then:
sudo apt install \
  ./boat-container-store_*.deb \
  ./boat-homeassistant-container_*.deb \
  ./boat-music-assistant-container_*.deb \
  ./boat-snapclient-container_*.deb
```

After install:

1. **Music Assistant** — open `https://halos.local/music-assistant/`. Enable the
   Spotify, Spotify Connect, Radio Browser, Filesystem, and Snapcast providers
   in MA's settings. Spotify Premium is required for the Spotify providers.
2. **Home Assistant** — open `https://halos.local/homeassistant/`. Complete
   onboarding, install the Music Assistant integration, and build a Lovelace
   view containing the MA media-player card.
3. **Local music library** — drop files into
   `/var/lib/container-apps/boat-music-assistant-container/library/` and trigger
   a Filesystem rescan in MA.

See [the plan](https://github.com/USER/halpi2-boat-containers/blob/main/docs/plan.md)
for the full architecture write-up.

## Releases

Tag a version (`v0.1.0`, etc.) and the `release.yml` workflow attaches the
built `.deb` files to the GitHub Release. There is no APT repository for this
project; install via direct `.deb` download.

## License

MIT — see [LICENSE](LICENSE). Individual upstream apps retain their own
licenses.
