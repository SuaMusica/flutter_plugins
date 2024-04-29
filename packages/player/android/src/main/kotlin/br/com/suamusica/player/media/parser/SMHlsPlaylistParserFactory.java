package br.com.suamusica.player.media.parser;

import androidx.annotation.Nullable;

import java.util.Collections;
import java.util.List;

import androidx.annotation.OptIn;
import androidx.media3.common.StreamKey;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.hls.playlist.HlsMediaPlaylist;
import androidx.media3.exoplayer.hls.playlist.HlsMultivariantPlaylist;
import androidx.media3.exoplayer.hls.playlist.HlsPlaylist;
import androidx.media3.exoplayer.hls.playlist.HlsPlaylistParserFactory;
import androidx.media3.exoplayer.offline.FilteringManifestParser;
import androidx.media3.exoplayer.upstream.ParsingLoadable;

public final class SMHlsPlaylistParserFactory implements HlsPlaylistParserFactory {

    private final List<StreamKey> streamKeys;

    /** Creates an instance that does not filter any parsing results. */
    public SMHlsPlaylistParserFactory() {
        this(Collections.<StreamKey>emptyList());
    }


    public SMHlsPlaylistParserFactory(List<StreamKey> streamKeys) {
        this.streamKeys = streamKeys;
    }

    @OptIn(markerClass = UnstableApi.class) @Override
    public ParsingLoadable.Parser<HlsPlaylist> createPlaylistParser() {
        return new FilteringManifestParser<>(new CustomHlsPlaylistParser(), streamKeys);
    }

    @Override
    public ParsingLoadable.Parser<HlsPlaylist> createPlaylistParser(HlsMultivariantPlaylist multivariantPlaylist, @Nullable HlsMediaPlaylist previousMediaPlaylist) {
        return null;
    }

    @Override
    public ParsingLoadable.Parser<HlsPlaylist> createPlaylistParser(HlsMultivariantPlaylist multivariantPlaylist, @Nullable HlsMediaPlaylist previousMediaPlaylist) {
        return new FilteringManifestParser<>(new CustomHlsPlaylistParser(), streamKeys);
    }

}
