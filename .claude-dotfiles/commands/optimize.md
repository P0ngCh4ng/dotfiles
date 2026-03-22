# Optimize - Performance Optimization with Strategic Planning

Optimize code performance with strategic planning and security-conscious implementation.

$ARGUMENTS (target: file, directory, or feature to optimize)

---

## Workflow

### Phase 1: Performance Analysis

1. **Identify Optimization Target**
   - Parse $ARGUMENTS: file path, directory, or feature name
   - Determine scope (single function, file, module, or system-wide)
   - Identify programming language and framework

2. **Baseline Measurement**
   - **Web/API**: Response times, throughput, latency
   - **Database**: Query execution time, index usage, N+1 queries
   - **Frontend**: Load time, FCP, LCP, TTI, bundle size
   - **Backend**: CPU usage, memory usage, I/O operations
   - **Algorithms**: Time complexity, space complexity

3. **Profiling and Benchmarking**
   - Run performance profiler appropriate for language:
     - **Node.js**: `node --prof`, Chrome DevTools
     - **Python**: `cProfile`, `line_profiler`
     - **Go**: `pprof`, benchmarks
     - **Ruby**: `ruby-prof`, `benchmark-ips`
   - Collect baseline metrics before optimization
   - Identify bottlenecks (hot paths, slow functions)

### Phase 2: Multi-Agent Strategic Planning (Parallel Launch)

**Launch planner and code-reviewer in PARALLEL:**

#### Agent 1: Strategic Optimization Planning

```javascript
Task({
  subagent_type: "planner",
  description: "Performance optimization strategy",
  prompt: `Create strategic performance optimization plan.

Target: ${optimization_target}
Baseline metrics: ${baseline_metrics}
Profiling results: ${profiling_data}
Bottlenecks identified: ${bottlenecks}

Analyze and plan:
1. Root cause analysis (why is it slow?)
2. Optimization strategies (prioritized by impact/effort)
3. Expected performance gains (quantified)
4. Implementation steps
5. Measurement strategy (how to verify improvement)

Consider:
- Algorithm optimization (better time/space complexity)
- Caching strategies (Redis, in-memory, CDN)
- Database optimization (indexes, query optimization, connection pooling)
- Lazy loading and code splitting
- Parallel processing and concurrency
- Resource compression (minification, gzip, brotli)
- Asset optimization (images, fonts, bundles)

Prioritize by:
- Impact (performance gain)
- Effort (implementation time)
- Risk (potential for regression)

Output: Step-by-step optimization plan with expected gains`
})
```

#### Agent 2: Security and Quality Pre-Check

```javascript
Task({
  subagent_type: "code-reviewer",
  description: "Security-conscious optimization review",
  prompt: `Review optimization target for security and quality considerations.

Target: ${optimization_target}
Current code: ${current_code}

Check for:
- Security implications of caching (sensitive data exposure)
- Race conditions from concurrency optimizations
- Data integrity risks (eventual consistency, cache invalidation)
- Resource exhaustion (memory leaks, connection leaks)
- Error handling in optimized paths
- Existing best practices that must be maintained

Identify:
- Security-sensitive areas (must not compromise security for speed)
- Quality metrics to maintain (maintainability, readability)
- Potential side effects of optimization
- Test coverage requirements

Output: Security and quality constraints for optimization plan`
})
```

**Both agents run in PARALLEL** for comprehensive analysis

### Phase 3: Synthesize Optimization Strategy

1. **Combine Agent Insights**
   - Planner's optimization strategies
   - Code-reviewer's security/quality constraints
   - Resolve conflicts (e.g., caching vs. data freshness)

2. **Prioritized Optimization Plan**
   ```markdown
   ## Performance Optimization Plan: ${target}

   ### Current State
   - Baseline metrics: ${metrics}
   - Identified bottlenecks: ${bottlenecks}
   - Performance goals: ${goals}

   ### Optimization Strategies (Prioritized)

   #### 1. [High Impact, Low Effort] ${strategy_1}
   - **Expected gain:** ${gain_percentage}% improvement
   - **Implementation:** ${steps}
   - **Risk:** Low
   - **Effort:** ${hours} hours
   - **Security considerations:** ${security_notes}

   #### 2. [High Impact, Medium Effort] ${strategy_2}
   - ...

   ### Implementation Steps
   1. Set up performance monitoring
   2. Implement optimization 1
   3. Measure improvement
   4. Verify no regressions (tests + security)
   5. Implement optimization 2
   6. ...

   ### Measurement Strategy
   - Metrics to track: ${metrics_list}
   - Success criteria: ${success_criteria}
   - Regression detection: ${regression_tests}

   ### Security & Quality Constraints
   - ${constraint_1}
   - ${constraint_2}

   ### Rollback Plan
   - If performance doesn't improve: ${rollback_steps}
   - If regressions detected: ${mitigation}
   ```

### Phase 4: User Confirmation

**Present plan and wait for approval:**

```markdown
## Optimization Plan Ready

**Multi-agent analysis complete:**
- 🏗️ planner: ${strategy_count} optimization strategies identified
- 🔍 code-reviewer: ${constraint_count} security/quality constraints

**Expected Performance Gain:** ${total_gain}%

**Top 3 Optimizations:**
1. ${opt_1} - ${gain_1}% improvement
2. ${opt_2} - ${gain_2}% improvement
3. ${opt_3} - ${gain_3}% improvement

**Next Steps:**
- ✅ Approve: Proceed with implementation
- 📝 Modify: Adjust optimization strategies
- 🔬 Benchmark: Run more detailed profiling first

Would you like me to proceed with implementation?
```

### Phase 5: Implementation (After Approval)

1. **Set Up Monitoring**
   - Add performance tracking
   - Set up alerts for regressions
   - Enable profiling in staging/dev

2. **Implement Optimizations Iteratively**
   - Implement one optimization at a time
   - Measure impact after each change
   - Verify no regressions (run tests)
   - Compare metrics to baseline

3. **Verify Security and Quality**
   - Auto-launch `code-reviewer` after each optimization
   - Run security checks
   - Run full test suite
   - Check for memory leaks, race conditions

4. **Document Changes**
   - Update comments explaining optimization
   - Document trade-offs made
   - Update performance documentation
   - Add benchmarks for regression prevention

### Phase 6: Post-Optimization Verification

1. **Measure Actual Gains**
   - Compare to baseline metrics
   - Verify meets success criteria
   - Check for unexpected side effects

2. **Final Review**
   - Auto-launch `code-reviewer` for final check
   - Verify all tests pass
   - Verify no security regressions
   - Verify no quality degradation

3. **Report Results**
   ```markdown
   ## Optimization Results

   **Baseline:**
   - Metric 1: ${baseline_1}
   - Metric 2: ${baseline_2}

   **Optimized:**
   - Metric 1: ${optimized_1} (${improvement_1}% better)
   - Metric 2: ${optimized_2} (${improvement_2}% better)

   **Optimizations Applied:**
   1. ${optimization_1} - ${gain_1}% improvement
   2. ${optimization_2} - ${gain_2}% improvement

   **Total Improvement:** ${total_improvement}%

   **Trade-offs:**
   - ${tradeoff_1}
   - ${tradeoff_2}

   **Next Steps:**
   - Monitor metrics in production
   - Consider additional optimizations (${future_opts})
   ```

---

## Optimization Categories

### 1. Algorithm Optimization
- Improve time complexity (O(n²) → O(n log n))
- Improve space complexity (reduce memory usage)
- Use more efficient data structures

### 2. Caching
- In-memory caching (Redis, Memcached)
- HTTP caching (ETag, Cache-Control)
- CDN for static assets
- Query result caching

### 3. Database Optimization
- Add indexes (analyze query plans)
- Optimize queries (avoid N+1, use joins)
- Connection pooling
- Read replicas for scaling
- Denormalization (where appropriate)

### 4. Frontend Optimization
- Code splitting (lazy load non-critical code)
- Bundle optimization (tree shaking, minification)
- Image optimization (compression, WebP, lazy loading)
- Reduce network requests (combine assets)
- Service workers for offline/caching

### 5. Backend Optimization
- Async processing (background jobs)
- Parallel processing (workers, threads)
- Streaming (for large data)
- Connection pooling
- Resource compression (gzip, brotli)

### 6. Infrastructure Optimization
- Horizontal scaling (load balancing)
- Vertical scaling (more resources)
- CDN usage
- Geographic distribution
- Auto-scaling

---

## Security Considerations

**Never compromise security for performance:**
- ✅ Cache non-sensitive data only
- ✅ Validate cached data before use
- ✅ Implement cache invalidation correctly
- ✅ Prevent cache poisoning attacks
- ✅ Maintain authentication/authorization checks
- ❌ Don't skip validation for performance
- ❌ Don't cache sensitive data without encryption
- ❌ Don't introduce race conditions

---

## Measurement Best Practices

### Before Optimization
- Establish baseline metrics
- Run profiler to identify bottlenecks
- Set clear success criteria (X% improvement)

### During Optimization
- Measure after each change
- Compare to baseline continuously
- Run benchmarks consistently (same environment)

### After Optimization
- Verify improvement in production
- Monitor for regressions
- Set up alerts for performance degradation

---

## Auto-Launch Conditions

This command automatically triggers when:
- User requests: "Optimize [feature/file]"
- User mentions: "performance", "slow", "speed up"
- Keywords: "最適化", "パフォーマンス改善", "高速化"

---

## Success Criteria

✅ Baseline metrics measured
✅ Bottlenecks identified via profiling
✅ Multi-agent optimization plan created
✅ Security and quality constraints identified
✅ Optimizations implemented iteratively
✅ Actual performance gains measured
✅ No security or quality regressions
✅ Results documented and verified

---

## Notes

- **Strategic approach:** Plan before optimizing (avoid premature optimization)
- **Measure everything:** Baseline, during, after (no guessing)
- **Security first:** Never compromise security for speed
- **Iterative:** One optimization at a time, measure impact
- **Multi-agent:** planner (strategy) + code-reviewer (security/quality)
