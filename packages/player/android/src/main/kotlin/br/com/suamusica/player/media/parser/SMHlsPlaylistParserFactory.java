//package br.com.suamusica.player.media.parser;
//
//import androidx.annotation.Nullable;
//
//import java.util.Collections;
//import java.util.List;
//
//import com.google.android.exoplayer2.offline.FilteringManifestParser;
//import androidx.media3.common.StreamKey;
//import com.google.media3.common.source.hls.playlist.HlsMediaPlaylist;
//import com.google.android.exoplayer2.source.hls.playlist.HlsMultivariantPlaylist;
//import com.google.android.exoplayer2.source.hls.playlist.HlsPlaylist;
//import com.google.android.exoplayer2.source.hls.playlist.HlsPlaylistParserFactory;
//import com.google.android.exoplayer2.upstream.ParsingLoadable;
//
//public final class SMHlsPlaylistParserFactory implements HlsPlaylistParserFactory {
//
//    private final List<StreamKey> streamKeys;
//
//    /** Creates an instance that does not filter any parsing results. */
//    public SMHlsPlaylistParserFactory() {
//        this(Collections.<StreamKey>emptyList());
//    }
//
//    /**
//     * Creates an instance that filters the parsing results using the given {@code streamKeys}.
//     *
//     * @param streamKeys See {@link
//     *     FilteringManifestParser#FilteringManifestParser(ParsingLoadable.Parser, List)}.
//     */
//    public SMHlsPlaylistParserFactory(List<StreamKey> streamKeys) {
//        this.streamKeys = streamKeys;
//    }
//
//    @Override
//    public ParsingLoadable.Parser<HlsPlaylist> createPlaylistParser() {
//        return new FilteringManifestParser<>(new CustomHlsPlaylistParser(), streamKeys);
//    }
//
//    @Override
//    public ParsingLoadable.Parser<HlsPlaylist> createPlaylistParser(HlsMultivariantPlaylist multivariantPlaylist, @Nullable HlsMediaPlaylist previousMediaPlaylist) {
//        return new FilteringManifestParser<>(new CustomHlsPlaylistParser(), streamKeys);
//    }
//
//}
