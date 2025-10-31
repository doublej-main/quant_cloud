/**
 * @file bs_price_call_t.hpp
 * @brief Templated Black-Scholes-Merton European call price.
 *
 * The function is templated on type `T`. This allows it to be used
 * for both standard pricing (with `T = double`) and for automatic
 * differentiation (e.g., complex-step differentiation with
 * `T = std::complex<double>`).
 *
 * It relies on the `Phi_t` dispatcher to correctly handle the
 * standard normal CDF calculation for the given type `T`.
 *
 * Exposes:
 * - bs_price_call_t(S, K, r, q, sigma, Tmat): Templated BSM call price.
 *
 * @see bs_templated_cdf_dispatcher.hpp (for the Phi_t implementation)
 */
#pragma once
#include "bs_templated_cdf_dispatcher.hpp"

// bs_price_call for complex numbers
template<class T>
T bs_price_call_t(T S, T K, T r, T q, T sigma, T Tmat)	{
	const	T DF		= std::exp(-r * Tmat);// Discount factor, TVM
	const	T F			= S * std::exp((r - q) * Tmat);// Forward price
	const	T sigmaT	= sigma * std::sqrt(Tmat);// Volatility scaled to time-to-maturity
	const	T d1		= (std::log(F / K) + 0.5 *sigma *sigma * Tmat) / sigmaT;// Probability to finish in the money
	const	T d2		= d1 - sigmaT;// Probability the option is exercised

	return DF * (F * Phi_t(d1) - K * Phi_t(d2));
}
