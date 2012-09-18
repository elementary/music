// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 */

/**
 * A central place for spawning threads.
 */
public class Noise.Threads {

    public delegate void TaskFunc ();

    private class TaskFuncWrapper : Object {
        public unowned TaskFunc func;

        public TaskFuncWrapper (TaskFunc func) {
            this.func = func;
        }
    }

    private const int MAX_THREADS = -1; // Unlimited
    private const int MAX_UNUSED_THREADS = 5;

    private static ThreadPool<TaskFuncWrapper>? thread_pool;


    /**
     * Adds //task// to the queue of tasks to be executed on a separate thread
     */
    public static void add (TaskFunc task) {
        if (thread_pool == null)
            init ();

        try {
            thread_pool.push (new TaskFuncWrapper (task));
        } catch (Error err) {
            critical ("Could not add task: %s", err.message);
        }
    }


    private static void init () {
        lock (thread_pool) {
            assert (thread_pool == null); // We want init() to be called only once

            try {
                thread_pool = new ThreadPool<TaskFuncWrapper> (task_func, MAX_THREADS, MAX_THREADS > 0);
            } catch (Error err) {
                error ("Couldn't create default thread pool: %s", err.message);
            }
        }

        thread_pool.set_max_unused_threads (MAX_UNUSED_THREADS);
    }

    private static void task_func (TaskFuncWrapper wrapper) {
        if (wrapper.func != null)
            wrapper.func ();
    }
}
