package br.com.suamusica.player.media.parser;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Collections;
import java.util.List;

import androidx.media3.common.StreamKey;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.hls.playlist.HlsMediaPlaylist;
import androidx.media3.exoplayer.hls.playlist.HlsMultivariantPlaylist;
import androidx.media3.exoplayer.hls.playlist.HlsPlaylist;
import androidx.media3.exoplayer.hls.playlist.HlsPlaylistParserFactory;
import androidx.media3.exoplayer.offline.FilteringManifestParser;
import androidx.media3.exoplayer.upstream.ParsingLoadable;

@UnstableApi
public final class SMHlsPlaylistParserFactory implements HlsPlaylistParserFactory {

    private final List<StreamKey> streamKeys;

    /**
     * Creates an instance that does not filter any parsing results.
     */
    public SMHlsPlaylistParserFactory() {
        this(Collections.<StreamKey>emptyList());
    }

    /**
     * Creates an instance that filters the parsing results using the given {@code streamKeys}.
     *
     * @param streamKeys See {@link
     *                   FilteringManifestParser#FilteringManifestParser(ParsingLoadable.Parser, List)}.
     */
    public SMHlsPlaylistParserFactory(List<StreamKey> streamKeys) {
        this.streamKeys = streamKeys;
    }

    @NonNull
    @Override
    public ParsingLoadable.Parser<HlsPlaylist> createPlaylistParser() {
        return new FilteringManifestParser<>(new CustomHlsPlaylistParser(), streamKeys);
    }

    @Override
    @NonNull
    public ParsingLoadable.Parser<HlsPlaylist> createPlaylistParser(@Nullable HlsMultivariantPlaylist hlsMultivariantPlaylist, @Nullable HlsMediaPlaylist previousMediaPlaylist) {
        return new FilteringManifestParser<>(new CustomHlsPlaylistParser(), streamKeys);
    }
}
