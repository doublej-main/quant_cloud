/**
 * @file main.cpp
 * @brief Main executable for validating Black-Scholes Greek calculation methods.
 *
 * This program compares the accuracy of:
 * 1. Finite Difference (FD) approximation.
 * 2. Complex-Step Differentiation (CSD).
 *
 * It validates these numerical methods against the analytic formulas for Delta and Gamma.
 *
 * The validation is run across a logarithmic range of step sizes (h)
 * and for different market scenarios (ATM, near-expiry).
 * The results, including the calculated values and their absolute errors,
 * are written to CSV files for easy analysis and plotting.
 *
 * Exposes:
 * - struct Scenario:					Holds market data for a single test case.
 * - run_validation(const Scenario&):	Runs the test for one scenario and writes a CSV.
 * - main():							Program entry point.
 *
 * @see bs_greeks.hpp
 */
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <iomanip>
#include "bs_greeks.hpp"

struct Scenario	{
	double S, K, r, q, sigma, T;
	std::string name;
};

void	run_validation(const Scenario& sc)	{
	std::string filename = "bs_fd_vs_complex_" + sc.name + ".csv";
	std::ofstream csv_file(filename);

    csv_file << "h_rel,h,"
             << "Delta_analytic,Delta_fd,Delta_cs,err_D_fd,err_D_cs,"
             << "Gamma_analytic,Gamma_fd,Gamma_cs_real,Gamma_cs_45,"
             << "err_G_fd,err_G_cs_real,err_G_cs_45\n";

	csv_file << std::fixed << std::setprecision(18);
	const double	delta_true = analytic_delta(sc.S, sc.K, sc.r, sc.q, sc.sigma, sc.T);
	const double	gamma_true = analytic_gamma(sc.S, sc.K, sc.r, sc.q, sc.sigma, sc.T);

	int	steps = 24;
	for (int i = 0; i <= steps; ++i)	{
		double	h_rel	= std::pow(10.0, -16.0 + (12.0 * i / steps));
		double	h		= h_rel * sc.S;

		// Calculate all greeks
		double	delta_fd		= ffd_delta(sc.S, sc.K, sc.r, sc.q, sc.sigma, sc.T, h);
		double	gamma_fd		= ffd_gamma(sc.S, sc.K, sc.r, sc.q, sc.sigma, sc.T, h);
		double	delta_cs		= csd_delta(sc.S, sc.K, sc.r, sc.q, sc.sigma, sc.T, h);
		double	gamma_cs_real	= csd_gamma_real(sc.S, sc.K, sc.r, sc.q, sc.sigma, sc.T, h);
		double	gamma_cs_45		= csd_gamma_45(sc.S, sc.K, sc.r, sc.q, sc.sigma, sc.T, h);

		// Calculate errors
		double	err_D_fd		= std::abs(delta_fd - delta_true);
		double	err_D_cs		= std::abs(delta_cs - delta_true);
		double	err_G_fd		= std::abs(gamma_fd - gamma_true);
		double	err_G_cs_real	= std::abs(gamma_cs_real - gamma_true);
		double	err_G_cs_45		= std::abs(gamma_cs_45 - gamma_true);

		// Write to CSV
		csv_file << h_rel << "," << h << ","
                 << delta_true << "," << delta_fd << "," << delta_cs << ","
                 << err_D_fd << "," << err_D_cs << ","
                 << gamma_true << "," << gamma_fd << "," << gamma_cs_real << "," << gamma_cs_45 << ","
                 << err_G_fd << "," << err_G_cs_real << "," << err_G_cs_45 << "\n";
	}
	csv_file.close();
	std::cout << "Succesfully generated " << filename << std::endl;
}

int	main(void)	{
	// ATM reference
	Scenario	s1	= {100.0, 100.0, 0.0, 0.0, 0.20, 1.0, "scenario1"};

	// Near-expiry, low-vol, ATM
	Scenario	s2	= {100.0, 100.0, 0.0, 0.0, 0.01, 1.0/365.0, "scenario2"};

	run_validation(s1);
	run_validation(s2);
	return 0;
}
