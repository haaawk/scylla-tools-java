package org.apache.cassandra.tools;

import java.util.function.Supplier;

public class Profiler {

	public static void profile(String name, Runnable task) {
		long startTime = System.currentTimeMillis();
		try {
			task.run();
		} finally {
			long endTime = System.currentTimeMillis();
			System.err.println(name + " took " + (endTime - startTime) + " ms");
		}
	}
	
	public static <T> T profile(String name, Supplier<T> task) {
		long startTime = System.currentTimeMillis();
		try {
			return task.get();
		} finally {
			long endTime = System.currentTimeMillis();
			System.err.println(name + " took " + (endTime - startTime) + " ms");
		}
	}
	
}
