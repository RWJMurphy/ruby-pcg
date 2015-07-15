require 'ffi'
require 'pcg/version'

module PCG
  module Binding
    class StateSetSeq64 < FFI::Struct
      layout :state, :uint64,
               :inc, :uint64
    end

    extend FFI::Library
    ffi_lib File.join(File.dirname(__FILE__), '..', 'ext', 'libpcg_random.dylib')

    # from pcg_variants.h:
    #
    # //// random_r
    # #define pcg32_random_r                  pcg_setseq_64_xsh_rr_32_random_r
    # #define pcg32s_random_r                 pcg_oneseq_64_xsh_rr_32_random_r
    # #define pcg32u_random_r                 pcg_unique_64_xsh_rr_32_random_r
    # #define pcg32f_random_r                 pcg_mcg_64_xsh_rs_32_random_r
    # //// boundedrand_r
    # #define pcg32_boundedrand_r             pcg_setseq_64_xsh_rr_32_boundedrand_r
    # #define pcg32s_boundedrand_r            pcg_oneseq_64_xsh_rr_32_boundedrand_r
    # #define pcg32u_boundedrand_r            pcg_unique_64_xsh_rr_32_boundedrand_r
    # #define pcg32f_boundedrand_r            pcg_mcg_64_xsh_rs_32_boundedrand_r
    # //// srandom_r
    # #define pcg32_srandom_r                 pcg_setseq_64_srandom_r
    # #define pcg32s_srandom_r                pcg_oneseq_64_srandom_r
    # #define pcg32u_srandom_r                pcg_unique_64_srandom_r
    # #define pcg32f_srandom_r                pcg_mcg_64_srandom_r
    # //// advance_r
    # #define pcg32_advance_r                 pcg_setseq_64_advance_r
    # #define pcg32s_advance_r                pcg_oneseq_64_advance_r
    # #define pcg32u_advance_r                pcg_unique_64_advance_r
    # #define pcg32f_advance_r                pcg_mcg_64_advance_r

    # The API centers around these functions:
    #
    #   void     pcg32_srandom_r(pcg32_random_t* rngptr, uint64_t initstate, uint64_t initseq)
    #   uint32_t pcg32_random_r(pcg32_random_t* rngptr)
    #   uint32_t pcg32_boundedrand_r(pcg32_random_t* rngptr, uint32_t bound)
    #   void     pcg32_advance_r(pcg32_random_t* rngptr, uint64_t delta)

    attach_function :pcg_setseq_64_srandom_r, [:pointer, :uint64, :uint64], :void
    attach_function :pcg_setseq_64_xsh_rr_32_random_r, [:pointer], :uint32
    attach_function :pcg_setseq_64_xsh_rr_32_boundedrand_r, [:pointer, :uint32], :uint32
    attach_function :pcg_setseq_64_advance_r, [:pointer, :uint64], :void

    # and these variants for the global RNG:
    #
    #   void     pcg32_srandom(uint64_t initstate, uint64_t initseq)
    #   uint32_t pcg32_random()
    #   uint32_t pcg32_boundedrand(uint32_t bound)
    #   void     pcg32_advance(uint64_t delta)

    # attach_function :pcg32_srandom, [:uint64, :uint64], :void
    # attach_function :pcg32_random, [], :uint32
    # attach_function :pcg32_boundedrand, [:uint32], :uint32
    # attach_function :pcg32_advance, [:uint64], :void
  end

  class PCG
    def initialize
      @state = Binding::StateSetSeq64.new
      @seeded = false
    end
    attr_reader :seeded

    def srandom(state, sequence)
      Binding.pcg_setseq_64_srandom_r(@state, state, sequence)
      @seeded = true
    end

    def random(limit = nil)
      maybe_seed
      if limit
        Binding.pcg_setseq_64_xsh_rr_32_boundedrand_r(@state, limit)
      else
        Binding.pcg_setseq_64_xsh_rr_32_random_r(@state)
      end
    end

    def advance(steps)
      maybe_seed
      Binding.pcg_setseq_64_advance_r(@state, steps)
    end

    private

    def maybe_seed
      srandom(Time.now.to_i, @state.pointer.to_i) unless @seeded
    end
  end
end
