package io.flutter.plugins.videoplayer;

import static androidx.media3.common.Player.REPEAT_MODE_ALL;
import static androidx.media3.common.Player.REPEAT_MODE_OFF;

import android.content.Context;
import android.media.MediaFormat;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.common.AudioAttributes;
import androidx.media3.common.C;
import androidx.media3.common.Format;
import androidx.media3.common.MediaItem;
import androidx.media3.common.PlaybackParameters;
import androidx.media3.common.util.Util;
import androidx.media3.datasource.DefaultDataSourceFactory;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.SeekParameters;
import androidx.media3.exoplayer.source.ProgressiveMediaSource;
import androidx.media3.exoplayer.video.VideoFrameMetadataListener;
import io.flutter.view.TextureRegistry.SurfaceProducer;

/**
 * A class responsible for managing video playback using {@link ExoPlayer}.
 *
 * <p>
 * It provides methods to control playback, adjust volume, and handle seeking.
 */
public abstract class VideoPlayer {

    @NonNull
    protected final VideoPlayerCallbacks videoPlayerEvents;
    @Nullable
    protected final SurfaceProducer surfaceProducer;
    @NonNull
    protected ExoPlayer exoPlayer;

    /**
     * A closure-compatible signature since {@link java.util.function.Supplier}
     * is API level 24.
     */
    public interface ExoPlayerProvider {

        /**
         * Returns a new {@link ExoPlayer}.
         *
         * @return new instance.
         */
        @NonNull
        ExoPlayer get();
    }

    /**
     * Constructs the VideoPlayer with all necessary dependencies.
     *
     * @param context The Android application context.
     * @param events Callbacks for player events.
     * @param mediaItem The media item to play.
     * @param options Playback options.
     * @param surfaceProducer The Flutter surface producer.
     * @param exoPlayerProvider Provider for ExoPlayer instances.
     */
    public VideoPlayer(
            @NonNull Context context,
            @NonNull VideoPlayerCallbacks events,
            @NonNull MediaItem mediaItem,
            @NonNull VideoPlayerOptions options,
            @Nullable SurfaceProducer surfaceProducer,
            @NonNull ExoPlayerProvider exoPlayerProvider) {
        this.videoPlayerEvents = events;
        this.surfaceProducer = surfaceProducer;

        // Create ExoPlayer instance
        exoPlayer = exoPlayerProvider.get();

        // Build a data source factory with a proper User-Agent
        DefaultDataSourceFactory dataSourceFactory
                = new DefaultDataSourceFactory(
                        context,
                        Util.getUserAgent(context, "FlutterVideoPlayer"));

        // Create a progressive media source (Media3 picks extractors internally)
        ProgressiveMediaSource mediaSource
                = new ProgressiveMediaSource.Factory(dataSourceFactory)
                        .createMediaSource(mediaItem);

        exoPlayer.setMediaSource(mediaSource);
        exoPlayer.prepare();

        // Frame listener to handle metadata; ExoPlayer renders to the Flutter surface automatically
        exoPlayer.setVideoFrameMetadataListener(
                new VideoFrameMetadataListener() {
            @Override
            public void onVideoFrameAboutToBeRendered(
                    long presentationTimeUs,
                    long releaseTimeNs,
                    Format format,
                    @Nullable MediaFormat mediaFormat) {
                // no-op: frames are rendered automatically
            }
        });

        // Event listener for Flutter callbacks
        exoPlayer.addListener(createExoPlayerEventListener(exoPlayer, surfaceProducer));

        // Set audio attributes
        setAudioAttributes(exoPlayer, options.mixWithOthers);
    }

    @NonNull
    protected abstract ExoPlayerEventListener createExoPlayerEventListener(
            @NonNull ExoPlayer exoPlayer, @Nullable SurfaceProducer surfaceProducer);

    void sendBufferingUpdate() {
        videoPlayerEvents.onBufferingUpdate(exoPlayer.getBufferedPosition());
    }

    private static void setAudioAttributes(ExoPlayer exoPlayer, boolean isMixMode) {
        exoPlayer.setAudioAttributes(
                new AudioAttributes.Builder().setContentType(C.AUDIO_CONTENT_TYPE_MOVIE).build(),
                !isMixMode);
    }

    void play() {
        exoPlayer.play();
    }

    void pause() {
        exoPlayer.pause();
    }

    void setLooping(boolean value) {
        exoPlayer.setRepeatMode(value ? REPEAT_MODE_ALL : REPEAT_MODE_OFF);
    }

    void setVolume(double value) {
        float bracketedValue = (float) Math.max(0.0, Math.min(1.0, value));
        exoPlayer.setVolume(bracketedValue);
    }

    void setPlaybackSpeed(double value) {
        final PlaybackParameters playbackParameters = new PlaybackParameters((float) value);
        exoPlayer.setPlaybackParameters(playbackParameters);
    }

    void seekTo(int location) {
        exoPlayer.setSeekParameters(SeekParameters.EXACT);
        exoPlayer.seekTo(location);
    }

    long getPosition() {
        return exoPlayer.getCurrentPosition();
    }

    @NonNull
    public ExoPlayer getExoPlayer() {
        return exoPlayer;
    }

    public void dispose() {
        exoPlayer.release();
    }
}
