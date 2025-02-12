package com.newsblur.activity;

import android.content.Intent;
import android.os.Bundle;
import android.app.FragmentManager;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.Window;

import com.newsblur.R;
import com.newsblur.fragment.DefaultFeedViewDialogFragment;
import com.newsblur.fragment.ItemListFragment;
import com.newsblur.fragment.ReadFilterDialogFragment;
import com.newsblur.fragment.StoryOrderDialogFragment;
import com.newsblur.service.NBSyncService;
import com.newsblur.util.AppConstants;
import com.newsblur.util.DefaultFeedView;
import com.newsblur.util.DefaultFeedViewChangedListener;
import com.newsblur.util.FeedSet;
import com.newsblur.util.ReadFilter;
import com.newsblur.util.ReadFilterChangedListener;
import com.newsblur.util.StoryOrder;
import com.newsblur.util.StoryOrderChangedListener;
import com.newsblur.view.StateToggleButton.StateChangedListener;

public abstract class ItemsList extends NbActivity implements StateChangedListener, StoryOrderChangedListener, ReadFilterChangedListener, DefaultFeedViewChangedListener {

	public static final String EXTRA_STATE = "currentIntelligenceState";
	public static final String EXTRA_BLURBLOG_USERNAME = "blurblogName";
	public static final String EXTRA_BLURBLOG_USERID = "blurblogId";
	public static final String EXTRA_BLURBLOG_USER_ICON = "userIcon";
	public static final String EXTRA_BLURBLOG_TITLE = "blurblogTitle";
	private static final String STORY_ORDER = "storyOrder";
	private static final String READ_FILTER = "readFilter";
    private static final String DEFAULT_FEED_VIEW = "defaultFeedView";
    public static final String BUNDLE_FEED_IDS = "feedIds";

	protected ItemListFragment itemListFragment;
	protected FragmentManager fragmentManager;
	protected int currentState;

    private FeedSet fs;
	
	protected boolean stopLoading = false;
    private int lastRequestedStoryCount = 0;

	@Override
    protected void onCreate(Bundle bundle) {
        this.fs = createFeedSet();

		requestWindowFeature(Window.FEATURE_PROGRESS);
		requestWindowFeature(Window.FEATURE_INDETERMINATE_PROGRESS);
		super.onCreate(bundle);

		setContentView(R.layout.activity_itemslist);
		fragmentManager = getFragmentManager();

        // our intel state is entirely determined by the state of the Main view
		currentState = getIntent().getIntExtra(EXTRA_STATE, 0);
		getActionBar().setDisplayHomeAsUpEnabled(true);

        getFirstStories();
	}

    protected abstract FeedSet createFeedSet();

    public FeedSet getFeedSet() {
        return this.fs;
    }

    @Override
    protected void onResume() {
        super.onResume();
        stopLoading = false;
        // this view shows stories, it is not safe to perform cleanup
        NBSyncService.holdStories(true);
        // Reading activities almost certainly changed the read/unread state of some stories. Ensure
        // we reflect those changes promptly.
        itemListFragment.hasUpdated();
    }

    private void getFirstStories() {
        stopLoading = false;
        lastRequestedStoryCount = 0;
        triggerRefresh(AppConstants.READING_STORY_PRELOAD);
    }

    @Override
    protected void onPause() {
        stopLoading = true;
        NBSyncService.holdStories(false);
        super.onPause();
    }

	public void triggerRefresh(int desiredStoryCount) {
		if (!stopLoading) {
            // this method tends to get called repeatedly. don't constantly keep requesting the same count!
            if (desiredStoryCount <= lastRequestedStoryCount) {
                return;
            }
            lastRequestedStoryCount = desiredStoryCount;

            boolean moreLeft = NBSyncService.requestMoreForFeed(fs, desiredStoryCount);
            if (moreLeft) {
                triggerSync();
            } else {
                stopLoading = true;
            }
		}
    }

	public abstract void markItemListAsRead();
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		if (item.getItemId() == android.R.id.home) {
			finish();
			return true;
		} else if (item.getItemId() == R.id.menu_mark_all_as_read) {
			markItemListAsRead();
			return true;
		} else if (item.getItemId() == R.id.menu_story_order) {
            StoryOrder currentValue = getStoryOrder();
            StoryOrderDialogFragment storyOrder = StoryOrderDialogFragment.newInstance(currentValue);
            storyOrder.show(getFragmentManager(), STORY_ORDER);
            return true;
        } else if (item.getItemId() == R.id.menu_read_filter) {
            ReadFilter currentValue = getReadFilter();
            ReadFilterDialogFragment readFilter = ReadFilterDialogFragment.newInstance(currentValue);
            readFilter.show(getFragmentManager(), READ_FILTER);
            return true;
        } else if (item.getItemId() == R.id.menu_default_view) {
            DefaultFeedView currentValue = getDefaultFeedView();
            DefaultFeedViewDialogFragment readFilter = DefaultFeedViewDialogFragment.newInstance(currentValue);
            readFilter.show(getFragmentManager(), DEFAULT_FEED_VIEW);
            return true;
        }
	
		return false;
	}
	
	protected abstract StoryOrder getStoryOrder();
	
	protected abstract ReadFilter getReadFilter();

    protected abstract DefaultFeedView getDefaultFeedView();
	
    @Override
	public void handleUpdate() {
        setProgressBarIndeterminateVisibility(NBSyncService.isFeedSetSyncing(this.fs));
		if (itemListFragment != null) {
            itemListFragment.syncDone();
			itemListFragment.hasUpdated();
        }
    }

	@Override
	public void changedState(int state) {
		itemListFragment.changeState(state);
	}
	
	@Override
    public void storyOrderChanged(StoryOrder newValue) {
        updateStoryOrderPreference(newValue);
        NBSyncService.resetFeed(fs); 
        itemListFragment.setStoryOrder(newValue);
        itemListFragment.resetEmptyState();
        itemListFragment.hasUpdated();
        itemListFragment.scrollToTop();
        getFirstStories();
    }
	
	public abstract void updateStoryOrderPreference(StoryOrder newValue);

    @Override
    public void readFilterChanged(ReadFilter newValue) {
        updateReadFilterPreference(newValue);
        NBSyncService.resetFeed(fs); 
        itemListFragment.resetEmptyState();
        itemListFragment.hasUpdated();
        itemListFragment.scrollToTop();
        getFirstStories();
    }

    protected abstract void updateReadFilterPreference(ReadFilter newValue);
}
