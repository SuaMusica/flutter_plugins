package br.com.suamusica.player.media.parser;

import java.util.Collections;
import java.util.List;

import com.google.android.exoplayer2.offline.FilteringManifestParser;
import com.google.android.exoplayer2.offline.StreamKey;
import com.google.android.exoplayer2.source.hls.playlist.HlsMasterPlaylist;
import com.google.android.exoplayer2.source.hls.playlist.HlsPlaylist;
import com.google.android.exoplayer2.source.hls.playlist.HlsPlaylistParserFactory;
import com.google.android.exoplayer2.upstream.ParsingLoadable;

public final class SMHlsPlaylistParserFactory implements HlsPlaylistParserFactory {

    private final List<StreamKey> streamKeys;

    /** Creates an instance that does not filter any parsing results. */
    public SMHlsPlaylistParserFactory() {
        this(Collections.<StreamKey>emptyList());
    }

    /**
     * Creates an instance that filters the parsing results using the given {@code streamKeys}.
     *
     * @param streamKeys See {@link
     *     FilteringManifestParser#FilteringManifestParser(ParsingLoadable.Parser, List)}.
     */
    public SMHlsPlaylistParserFactory(List<StreamKey> streamKeys) {
        this.streamKeys = streamKeys;
    }

    @Override
    public ParsingLoadable.Parser<HlsPlaylist> createPlaylistParser() {
        return new FilteringManifestParser<>(new CustomHlsPlaylistParser(), streamKeys);
    }

    @Override
    public ParsingLoadable.Parser<HlsPlaylist> createPlaylistParser(HlsMasterPlaylist masterPlaylist) {
        return new FilteringManifestParser<>(new CustomHlsPlaylistParser(), streamKeys);
    }
}
